{
  "$schema" = "https://opencode.ai/config.json";

  instructions = [
    "AGENTS.md"
    "https://raw.githubusercontent.com/nvk/llm-wiki/master/plugins/llm-wiki-opencode/skills/wiki-manager/SKILL.md"
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
        "glm-5.2-fp8" = {
          name = "GLM 5.2 (darkmatter)";
          reasoning = true;
          temperature = true;
          tool_call = true;
          variants = {
            thinking = {
              thinking = {
                reasoningEffort = "max";
              };
            };
            nothink = {
              thinking = {
                type = "disabled";
              };
            };
          };
          limit = {
            context = 1048576;
            output = 131072;
          };
        };
        "glm-5.2-q5-gguf" = {
          name = "GLM 5.2 Q5 (darkmatter)";
          reasoning = true;
          temperature = true;
          tool_call = true;
          variants = {
            thinking = {
              thinking = {
                reasoningEffort = "max";
              };
            };
            nothink = {
              thinking = {
                type = "disabled";
              };
            };
          };
          limit = {
            context = 52428;
            output = 65072;
          };
        };
        "kimi-k2.7-code" = {
          name = "Kimi K2.7 Code (darkmatter)";
          reasoning = true;
          temperature = false;
          tool_call = true;
          limit = {
            context = 262144;
            output = 32768;
          };
        };
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
      command = [
        "npx"
        "-y"
        "@morphllm/morphmcp"
      ];
      environment = {
        ENABLED_TOOLS = "edit_file,warpgrep_codebase_search";
      };
    };
    context7 = {
      type = "local";
      command = [
        "npx"
        "-y"
        "@upstash/context7-mcp"
      ];
      enabled = true;
      environment = { };
    };
    "cloudflare-docs" = {
      type = "remote";
      url = "https://docs.mcp.cloudflare.com/sse";
      enabled = true;
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
