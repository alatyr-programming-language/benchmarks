#!/usr/bin/env bash
# Build and benchmark each benchmark across the languages below, then print a
# boxed table per benchmark.
#
#   ./run.sh                 # every benchmark under benchmarks/ (in dir order)
#   ./run.sh 02_primes       # just that one benchmark directory
#   REPEAT=10 ./run.sh       # best of 10 (default 5);  NO_COLOR=1 disables colour
#
# Layout: benchmarks/<NN_dir>/<name>.{al,c,rs,zig,go,ts,js,php,rb,py} — the SAME
# algorithm per language. Directories carry an ordering prefix by increasing
# complexity (01_hello, 02_primes, 03_arraysum); the benchmark name is the `.al`
# stem. Columns = languages; each metric is its own row:
#   Time   best run wall-clock of REPEAT runs
#   Build  compile+link time (compiled langs; `-` for interpreted)
#   Mem    peak resident set (max RSS; needs GNU `time`)
#   Bin    compiled binary size (`-` for interpreted)
#   Src    source file size
# In each metric row the **best** value is green and the **worst** red. A missing
# optional toolchain shows `-`; an Alatyr build or run failure aborts the run.
# Correctness: the first language's output is
# the reference (`!` flags a mismatch). Run from the dev shell (or let the script
# re-exec under direnv). The Alatyr compiler is NOT built here — this repository does not contain it.
# Point `ALATYR` at a built compiler, or put `alatyr` on PATH:
#
#     ALATYR=/path/to/alatyr ./run.sh            # or: ./run.sh, with `alatyr` on PATH
#
# Build one from https://github.com/alatyr-programming-language/compiler (`seed/alatyr build
# package.al` -> `target/debug/alatyr`). There is no `cargo` build — Alatyr is self-hosted.
set -uo pipefail

self="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
cd "$(dirname "$self")"
need_shell=0
for tool in cc rustc zig go node php ruby python3 as ld; do
  command -v "$tool" >/dev/null 2>&1 || { need_shell=1; break; }
done
if [ -z "${BENCH_IN_SHELL:-}" ] && [ "$need_shell" = 1 ]; then
  if command -v direnv >/dev/null 2>&1; then export BENCH_IN_SHELL=1; exec direnv exec . "$self" "$@"; fi
  echo "note: comparison toolchain incomplete on PATH and no direnv to load it; run from inside the dev shell." >&2
fi

REPEAT="${REPEAT:-5}"
case "$REPEAT" in
  ''|0*|*[!0-9]*)
    echo "run.sh: REPEAT must be a positive integer (got '$REPEAT')." >&2
    exit 2
    ;;
esac
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
data="$work/data"; : >"$data"; notes="$work/notes"; : >"$notes"
export GOCACHE="$work/go-cache" GOPATH="$work/go" GOFLAGS=-mod=mod

LANGS=(Alatyr C Rust Zig Go TypeScript JavaScript PHP Ruby Python)
declare -A EXT=([Alatyr]=al [C]=c [Rust]=rs [Zig]=zig [Go]=go [TypeScript]=ts [JavaScript]=js [PHP]=php [Ruby]=rb [Python]=py)
declare -A COMPILED=([Alatyr]=1 [C]=1 [Rust]=1 [Zig]=1 [Go]=1)

gtime=""
for t in /usr/bin/time "$(command -v gtime 2>/dev/null||true)" "$(command -v time 2>/dev/null||true)"; do
  [ -n "$t" ] && "$t" -f '%e %M' true >/dev/null 2>&1 && { gtime="$t"; break; }
done
# The self-hosted compiler binary. Resolution order: an explicit `ALATYR`, then `alatyr` on PATH.
# There is deliberately NO auto-build fallback: this repository holds no compiler, and the previous
# fallback ran `( cd .. && ./seed/alatyr build package.al ) || true`, which in a standalone checkout
# fails SILENTLY — Alatyr then vanished from the comparison table with only a `note:` on stderr. A
# benchmark suite that quietly drops the language it exists to measure is worse than one that refuses
# to start, so a missing or failing Alatyr compiler/benchmark is now a hard, named error.
alatyr_bin="${ALATYR:-}"
if [ -z "$alatyr_bin" ]; then alatyr_bin="$(command -v alatyr 2>/dev/null || true)"; fi
if [ -z "$alatyr_bin" ] || [ ! -x "$alatyr_bin" ]; then
  cat >&2 <<'EOF'
run.sh: no Alatyr compiler found — refusing to run.

This repository holds only the benchmark programs; the compiler lives in
  https://github.com/alatyr-programming-language/compiler

Build one and point this script at it:
  git clone https://github.com/alatyr-programming-language/compiler
  cd compiler && nix develop -c bash -c 'seed/alatyr build package.al'
  ALATYR="$PWD/target/debug/alatyr" ./run.sh          # from this directory

Or put `alatyr` on PATH. Refusing rather than skipping is deliberate: a comparison table without
the language it exists to measure looks like a result, and is not one.
EOF
  exit 2
fi

human() { awk -v b="$1" 'BEGIN{ if(b<0){print"-";exit} if(b>=1048576)printf"%.1fM",b/1048576; else if(b>=1024)printf"%.0fK",b/1024; else printf"%dB",b }'; }
prog()      { if [ -t 2 ]; then printf '\r\033[K%s' "$1" >&2; else printf '%s\n' "$1" >&2; fi; }
prog_done() { [ -t 2 ] && printf '\r\033[K' >&2 || true; }
rec() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" >>"$data"; }

# build LANG SRC OUT -> seconds (compiled, on success); failure returns 1.
build_lang() {
  local lang="$1" src="$2" out="$3" s e
  s="$(date +%s.%N)"
  case "$lang" in
    Alatyr)
      [ -x "$alatyr_bin" ] || return 1
      "$alatyr_bin" -o "$out" "$src" >/dev/null || return 1
      ;;
    C)      command -v cc    >/dev/null 2>&1 && cc -O2 -o "$out" "$src" 2>/dev/null || return 1;;
    Rust)   command -v rustc >/dev/null 2>&1 && rustc -O -o "$out" "$src" 2>/dev/null || return 1;;
    Zig)    command -v zig   >/dev/null 2>&1 && zig build-exe -O ReleaseFast "$src" -femit-bin="$out" --cache-dir "$work/zig" 2>/dev/null || return 1;;
    Go)     command -v go    >/dev/null 2>&1 && go build -o "$out" "$src" 2>/dev/null || return 1;;
    *) return 1;;
  esac
  [ -x "$out" ] || return 1
  e="$(date +%s.%N)"; awk -v a="$s" -v b="$e" 'BEGIN{printf"%.2f",b-a}'
}

# the command that RUNS the benchmark for LANG (binary, or interpreter + src).
run_cmd() {
  case "$1" in
    Alatyr|C|Rust|Zig|Go) echo "$3";;
    Python)     command -v python3 >/dev/null 2>&1 && echo "python3 $2";;
    TypeScript|JavaScript) command -v node >/dev/null 2>&1 && echo "node $2";;
    PHP)        command -v php  >/dev/null 2>&1 && echo "php $2";;
    Ruby)       command -v ruby >/dev/null 2>&1 && echo "ruby $2";;
  esac
}

run_bench() {
  local bench="$1" dir="$2" ref="" have_ref=0
  for lang in "${LANGS[@]}"; do
    local src="$dir/$bench.${EXT[$lang]}" out="$work/${bench}_${lang}"
    if [ ! -f "$src" ]; then for m in Time Build Mem Bin Src; do rec "$bench" "$lang" "$m" "-" -1; done; continue; fi
    prog "  benchmarking ${bench}: ${lang} …"
    local build="-" buildnum=-1 bin=-1
    if [ -n "${COMPILED[$lang]:-}" ]; then
      local bt
      if ! bt="$(build_lang "$lang" "$src" "$out")"; then
        if [ "$lang" = Alatyr ]; then
          echo "run.sh: Alatyr failed to build $src — refusing to run." >&2
          exit 2
        fi
        echo "note: $bench/$lang failed to build; column is '-'." >&2
        for m in Time Build Mem Bin Src; do rec "$bench" "$lang" "$m" "-" -1; done
        continue
      fi
      build="${bt}s"; buildnum="$bt"; bin="$(wc -c <"$out")"
    fi
    local runcmd; runcmd="$(run_cmd "$lang" "$src" "$out")"
    if [ -z "$runcmd" ]; then
      echo "note: $bench/$lang toolchain is unavailable; column is '-'." >&2
      for m in Time Build Mem Bin Src; do rec "$bench" "$lang" "$m" "-" -1; done
      continue
    fi
    local best="" rss=0 t m output run_status run_failed=0 fail_reason=""
    for _ in $(seq "$REPEAT"); do
      run_status=0
      if [ -n "$gtime" ]; then
        local meas
        "$gtime" -f '%e %M' -o "$work/t" $runcmd >"$work/o" 2>"$work/e" || run_status=$?
        meas="$(<"$work/t")"
        t="${meas% *}"; m="${meas##* }"
      else
        local s e; s="$(date +%s.%N)"; $runcmd >"$work/o" 2>"$work/e" || run_status=$?; e="$(date +%s.%N)"
        t="$(awk -v a="$s" -v b="$e" 'BEGIN{printf"%.3f",b-a}')"; m=0
      fi
      if [ "$run_status" -ne 0 ]; then
        run_failed=1; fail_reason="failed at runtime (exit $run_status)"; break
      fi
      output="$(cat "$work/o")"
      if [ -z "$output" ]; then
        run_failed=1; fail_reason="produced no stdout"; break
      fi
      [ "$have_ref" = 0 ] && { ref="$output"; have_ref=1; }
      [ "$output" = "$ref" ] || echo "  $bench/$lang: output differs from the reference" >>"$notes"
      { [ -z "$best" ] || awk -v x="$t" -v y="$best" 'BEGIN{exit !(x<y)}'; } && best="$t"
      [ "${m:-0}" -gt "$rss" ] 2>/dev/null && rss="$m"
    done
    if [ "$run_failed" = 1 ]; then
      if [ "$lang" = Alatyr ]; then
        echo "run.sh: Alatyr benchmark $bench $fail_reason — refusing to report a partial table." >&2
        [ -s "$work/e" ] && sed 's/^/  /' "$work/e" >&2
        exit 2
      fi
      echo "note: $bench/$lang $fail_reason; column is '-'." >&2
      [ -s "$work/e" ] && sed 's/^/  /' "$work/e" >&2
      for m in Time Build Mem Bin Src; do rec "$bench" "$lang" "$m" "-" -1; done
      continue
    fi
    local membytes=-1; [ "$rss" -gt 0 ] 2>/dev/null && membytes="$((rss*1024))"
    rec "$bench" "$lang" Time  "${best}s" "$best"
    rec "$bench" "$lang" Build "$build"   "$buildnum"
    rec "$bench" "$lang" Mem   "$(human "$membytes")" "$membytes"
    rec "$bench" "$lang" Bin   "$(human "$bin")" "$bin"
    rec "$bench" "$lang" Src   "$(human "$(wc -c <"$src")")" "$(wc -c <"$src")"
  done
}

# A benchmark is a directory holding one `<name>.al` (plus the same `<name>` in the
# other languages). The directory may carry an ordering prefix (`01_hello`, …) while
# the files keep their plain name (`hello.al`) — derive the benchmark name from the
# `.al` stem, keep the directory separate, so `<dir>/<name>.<ext>` resolves.
run_dir() {
  local dir="${1%/}"
  [ -d "$dir" ] || { echo "no such benchmark: $dir"; exit 1; }
  local al; al="$(ls "$dir"/*.al 2>/dev/null | head -1)"
  [ -n "$al" ] && [ -f "$al" ] || { echo "no .al source in $dir — skipping"; return; }
  run_bench "$(basename "$al" .al)" "$dir"
}

[ -n "$gtime" ] || echo "note: no GNU \`time\` — Mem shows '-'"
if [ "$#" -ge 1 ]; then
  run_dir "$1"
else
  found=0
  for d in */; do
    ls "${d%/}"/*.al >/dev/null 2>&1 || continue
    run_dir "${d%/}"; found=1
  done
  [ "$found" = 1 ] || { echo "no benchmarks found"; exit 1; }
fi
prog_done

color=1; { [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; } && color=0
awk -F'\t' -v color="$color" '
function rep(s,n,  o){o="";while(n-->0)o=o s;return o}
function spaces(n){ if(n<0)n=0; return rep(" ",n) }
function fit(s,vw,w){ return s spaces(w-vw) }
function paint(d,w,col,  n){ n=w-length(d); if(n<0)n=0; if(col&&color) return C[col] d R rep(" ",n); return d rep(" ",n) }
BEGIN{
  nl=split("Alatyr C Rust Zig Go TS JS PHP Ruby Py",LH," "); split("Alatyr C Rust Zig Go TypeScript JavaScript PHP Ruby Python",LK," ");
  nm=split("Time Build Mem Bin Src",MET," ");
  R="\033[0m"; C["g"]="\033[32m"; C["r"]="\033[31m"; HDR="benchmark";
  H="─"; V="│"; TL="┌"; TM="┬"; TR="┐"; ML="├"; MM="┼"; MR="┤"; BL="└"; BM="┴"; BR="┘";
}
{ disp[$1,$2,$3]=$4; num[$1,$2,$3]=$5+0; if(!($1 in seen)){seen[$1]=1; ord[++nb]=$1} }
END{
  w0=length(HDR); for(bi=1;bi<=nb;bi++) if(length(ord[bi])>w0)w0=length(ord[bi]);
  wm=0; for(mi=1;mi<=nm;mi++) if(length(MET[mi])>wm)wm=length(MET[mi]);
  for(li=1;li<=nl;li++){ wl[li]=length(LH[li]);
    for(bi=1;bi<=nb;bi++) for(mi=1;mi<=nm;mi++){ d=disp[ord[bi],LK[li],MET[mi]]; if(d=="")d="-"; if(length(d)>wl[li])wl[li]=length(d) } }
  top=TL rep(H,w0+2) TM rep(H,wm+2); mid=ML rep(H,w0+2) MM rep(H,wm+2); bot=BL rep(H,w0+2) BM rep(H,wm+2);
  for(li=1;li<=nl;li++){ top=top TM rep(H,wl[li]+2); mid=mid MM rep(H,wl[li]+2); bot=bot BM rep(H,wl[li]+2) }
  top=top TR; mid=mid MR; bot=bot BR;
  print top;
  row=V" " fit(HDR,length(HDR),w0) " " V" " fit("",0,wm) " ";
  for(li=1;li<=nl;li++) row=row V" " fit(LH[li],length(LH[li]),wl[li]) " "; print row V;
  print mid;
  for(bi=1;bi<=nb;bi++){ b=ord[bi];
    # best (min) / worst (max) lang per metric, over present numeric cells
    for(mi=1;mi<=nm;mi++){ lo=""; hi=""; loi=0; hii=0; cnt=0;
      for(li=1;li<=nl;li++){ v=num[b,LK[li],MET[mi]]; d=disp[b,LK[li],MET[mi]];
        if(d!="-" && d!="" && v>=0){ cnt++;
          if(lo==""||v<lo){lo=v;loi=li} if(hi==""||v>hi){hi=v;hii=li} } }
      best[mi]= (cnt>=1)?loi:0; worst[mi]=(cnt>=2 && hi>lo)?hii:0 }
    for(mi=1;mi<=nm;mi++){
      c0=(mi==1)?fit(b,length(b),w0):spaces(w0);
      row=V" " c0 " " V" " fit(MET[mi],length(MET[mi]),wm) " ";
      for(li=1;li<=nl;li++){ d=disp[b,LK[li],MET[mi]]; if(d=="")d="-";
        col=""; if(li==best[mi])col="g"; else if(li==worst[mi])col="r";
        row=row V" " paint(d,wl[li],col) " " }
      print row V }
    print (bi<nb ? mid : bot);
  }
}' "$data"

[ -s "$notes" ] && { echo; echo "mismatches:"; sort -u "$notes"; }
echo
echo "Time=best of $REPEAT · Build=compile+link · Mem=peak RSS · Bin=binary · Src=source · green=best red=worst"
