self:
{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.programs.lazyvim;
in
{
  options.programs.lazyvim.extras.lang.rust = {
    enable = mkEnableOption "the lang.rust extra";
  };

  config = mkIf cfg.extras.lang.rust.enable {
    programs.neovim = {
      extraPackages = with pkgs; [
        lldb
      ];

      plugins = with pkgs.vimPlugins; [
        # NOTE: enabling rust treesitter on Darwin leads to
        # error: The option `programs.neovim.plugins."[definition 2-entry 1]"
        # .__darwinAllowLocalNetworking' does not exist.
        (if pkgs.stdenv.isDarwin then
          pkgs.vimUtils.buildVimPlugin
            {
              inherit (nvim-treesitter.withPlugins (
                plugins: with plugins; [ rust ron ]
              )) pname version src meta;
              __darwinAllowLocalNetworking = true;
            }
        else
          nvim-treesitter.withPlugins (
            plugins: with plugins; [ rust ron ]
          )
        )
        #
        # NOTE: crates-nvim recent update required
        # crates-nvim
        # but fails to load crates.null-ls related to null-ls-nvim or none-ls-nvim
        # without overrides from 
        # https://github.com/NixOS/nixpkgs/blob/5092f59914b45d6e80e1650324eac988e7520907/pkgs/applications/editors/vim/plugins/overrides.nix#L891-L897
        (pkgs.vimUtils.buildVimPlugin {
          pname = "crates.nvim";
          version = "2025-02-20";
          src = pkgs.fetchFromGitHub {
            owner = "saecki";
            repo = "crates.nvim";
            rev = "1803c8b5516610ba7cdb759a4472a78414ee6cd4";
            sha256 = "0bqcdsbhs1ab51nmqd3cx7p6nlpmrjj0a53hax9scpqzr23nvr66";
          };
          meta.homepage = "https://github.com/saecki/crates.nvim/";
          # see overrides in nixpkgs/pkgs/applications/editors/vim/plugins/overrides.nix
          checkInputs = [
            none-ls-nvim
          ];
          dependencies = [
            plenary-nvim
          ];
        })
        rustaceanvim
        clangd_extensions-nvim
      ];
    };
  };
}
