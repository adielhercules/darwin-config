{ config, pkgs, ... }:

{
  home.file."Library/Application Support/Leader Key/config.json" = {
    source = ./leader_key/config.json;
  };
}
