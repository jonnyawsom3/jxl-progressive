{
  inputs = {
    crane.url = "github:ipetkov/crane";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    { crane, fenix, flake-utils, nixpkgs, ... }:

    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        toolchainSpec = {
          channel = "1.97.1";
          sha256 = "sha256-A1abGIbOtcBSdrUMhDGrER3pRM1hQP4fp9gh3Y4PKc8=";
        };
        fenix' = fenix.packages.${system};
        toolchain = fenix'.toolchainOf toolchainSpec;
        completeToolchain = fenix'.combine (with toolchain; [
          defaultToolchain
          rust-src
          rust-analyzer
        ]);

        craneLib = (crane.mkLib pkgs).overrideToolchain completeToolchain;

        packageExpr =
          {
            ffmpeg_8-headless,
            pkg-config,
            rustPlatform,
            ...
          }:
          craneLib.buildPackage {
            __structuredAttrs = true;
            strictDeps = true;

            src = craneLib.cleanCargoSource ./.;

            buildInputs = [
              ffmpeg_8-headless
            ];

            nativeBuildInputs = [
              pkg-config
              rustPlatform.bindgenHook
            ];

            doCheck = false;

            NIX_OUTPATH_USED_AS_RANDOM_SEED = "cccccccccc";
          };
      in
      {
        packages.default = pkgs.callPackage packageExpr {};

        devShells.default = craneLib.devShell {
          packages = with pkgs; [
            ffmpeg_8-headless
            pkg-config
            rustPlatform.bindgenHook
          ];
        };
      }
    );
}
