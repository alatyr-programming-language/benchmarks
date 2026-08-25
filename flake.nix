{
  description = "Alatyr benchmarks — the comparison toolchains, one shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        # One shell holding every language `run.sh` compares. Each is optional to the harness — a
        # missing or failing toolchain shows `-` in its column and is skipped — so this shell exists to
        # make the table COMPLETE rather than to make the script work: run it without these and you get a
        # comparison of Alatyr against nothing.
        #
        # The Alatyr compiler is deliberately NOT here. This repository holds no compiler and cannot
        # build one; point `ALATYR` at a build from
        # https://github.com/alatyr-programming-language/compiler, or put `alatyr` on PATH. A missing
        # missing or failing Alatyr compiler/benchmark is the harness's one hard error, because a table
        # without the language it exists to measure still looks like a result.
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # C comes from stdenv's `cc`, which mkShell already puts on PATH.
            rustc          # rustc -O
            zig            # zig build-exe -O ReleaseFast
            go             # go build
            nodejs         # `node <file>` for both the JavaScript and the TypeScript column
            php ruby python3

            # GNU `time`: the harness reads peak RSS from `time -f '%e %M'`. Without it every Mem
            # cell is `-` — the numbers that motivate a systems language are exactly the ones that
            # silently disappear, so this is not optional in practice.
            time

            hyperfine      # reproducible timing when a single case is being investigated by hand
          ];
        };
      });
}
