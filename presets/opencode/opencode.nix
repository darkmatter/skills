{
  "$schema" = "https://opencode.ai/config.json";

  instructions = [
    "AGENTS.md"
  ];

  permission = {
    "*" = "allow";
    edit = "allow";
    bash = "allow";
    skill = {
      "*" = "allow";
    };
  };

  share = "manual";
  autoupdate = "notify";
  lsp = true;

  provider = {
    litellm = {
      npm = "@ai-sdk/openai-compatible";
      name = "LiteLLM";
      options = {
        baseURL = "https://litellm.drkmttr.dev/v1";
        apiKey = "{file:~/.secrets/litellm-api-key}";
      };
      models = {
        "gpt-oss-120b" = {
          name = "GPT-OSS-120B (darkmatter)";
          reasoning = true;
          temperature = true;
          tool_call = true;
          variants = {
            high = {
              reasoningEffort = "high";
              textVerbosity = "low";
              reasoningSummary = "auto";
            };
            medium = {
              reasoningEffort = "medium";
              textVerbosity = "low";
              reasoningSummary = "auto";
            };
            low = {
              reasoningEffort = "low";
              textVerbosity = "low";
              reasoningSummary = "auto";
            };
          };
          limit = {
            context = 121000;
            output = 4096;
          };
        };
      };
    };
  };

  mcp = {
    "morph-mcp" = {
      type = "local";
      command = [ "npx" "-y" "@morphllm/morphmcp" ];
      environment = {
        ENABLED_TOOLS = "edit_file,warpgrep_codebase_search";
      };
    };
    context7 = {
      type = "local";
      command = [ "npx" "-y" "@upstash/context7-mcp" ];
      enabled = true;
      environment = { };
    };
    "cloudflare-docs" = {
      type = "remote";
      url = "https://docs.mcp.cloudflare.com/sse";
      enabled = true;
    };
    shadcn = {
      type = "local";
      command = [ "npx" "-y" "shadcn@latest" "mcp" ];
      enabled = true;
      environment = { };
    };
  };

  plugin = [
    "@warp-dot-dev/opencode-warp"
    "opencode-claude-auth@latest"
    "oh-my-openagent@latest"
    "opencode-beads"
  ];

  agent = {
    build = {
      enable1mContext = true;
    };
  };
}
