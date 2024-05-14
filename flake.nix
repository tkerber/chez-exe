{
  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        bootpath = "${pkgs.chez}/lib/csv${pkgs.chez.version}/${{
          x86_64-darwin = "ta6osx";
          x86_64-linux = "ta6le";
          aarch64-darwin = "tarm64osx";
          aarch64-linux = "tarm64le";
        }.${system}}";
        platformSpecificInputs = {
          x86_64-darwin = [ pkgs.darwin.libiconv ];
          x86_64-linux = [ pkgs.libuuid ];
          aarch64-darwin = [ pkgs.darwin.libiconv ];
          aarch64-linux = [ pkgs.libuuid ];
        }.${system};
      in {

        packages.default = pkgs.stdenv.mkDerivation {
          name = "chez-exe";
          version = "0.0.1";
          src = ./.;

          buildInputs = with pkgs; [
            chez
          ] ++ platformSpecificInputs;

          buildPhase = ''
            mkdir -p $out/{bin,lib}
            scheme --script gen-config.ss \
            --prefix $out \
            --bindir $out/bin \
            --libdir $out/lib \
            --bootpath ${bootpath} \
            --scheme scheme
          '';
        };
      }
    );
}
