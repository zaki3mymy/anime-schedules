{
  description = "anime-schedules の開発環境";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Python 本体は入れない。uv が .python-version を見て入れる（CI の setup-uv と同じ）
            # ruff などの Python のツールは、uv.lock で管理する（uv run で使う）
            uv
            # terraform は unfree でビルド済みのものがなく、ソースからのビルドに時間がかかるので入れない（別に入れる）
          ];
        };
      }
    );
}
