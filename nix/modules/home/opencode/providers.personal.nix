{
  # Ollama local models served via Ollama's OpenAI-compatible endpoint
  # (http://localhost:11434/v1). Requires the Ollama daemon to be running
  # and the model pulled locally (`ollama pull qwen3.8:latest`).
  #
  # Personal-laptop only — the Ollama daemon isn't set up on the work
  # machine, so this provider is merged in only when `profile == "personal"`
  # (see ./default.nix).
  ollama = {
    name = "Ollama (local)";
    package = "aisdk:@ai-sdk/openai-compatible";
    settings = {
      baseURL = "http://localhost:11434/v1";
    };
    models = {
      "qwen3.8:latest" = {
        name = "Qwen3.8";
        capabilities = {
          tools = true;
          input = [ "text" ];
          output = [ "text" ];
        };
        limit = {
          context = 127000;
          output = 32000;
        };
      };
    };
  };
}
