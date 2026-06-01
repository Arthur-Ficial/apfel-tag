// ============================================================================
// Help.swift - the --help / usage text for apfel-tag.
// ============================================================================

let helpText = """
apfel-tag v\(buildVersion) - on-device content tagging from the command line

USAGE:
  echo "text" | apfel-tag [OPTIONS]
  apfel-tag [OPTIONS] < file

  Reads text from standard input and classifies it into tags using Apple's
  on-device content-tagging model. 100% on-device, no network.

OPTIONS:
  -o, --output <plain|json>   Output format [default: plain]
      --kind <kind>           Label category: tags, topics, emotions, actions, all
                              [default: tags]
      --max-tags <n>          Cap the number of tags returned
      --permissive            Relax content guardrails (for benign input that is refused)
  -q, --quiet                 Suppress non-essential output
      --no-color              Disable colored output (also honors NO_COLOR)
  -h, --help                  Show this help and exit
  -v, --version               Show version and exit

EXAMPLES:
  echo "The headphones sound amazing." | apfel-tag
  echo "Kubernetes pods keep crashing." | apfel-tag -o json | jq -r '.tags[]'
  echo "A thrilling, scary movie night." | apfel-tag --kind emotions
  pbpaste | apfel-tag --kind all -o json

EXIT CODES:
  0  tags produced
  1  runtime error (model unavailable / refusal)
  2  no input piped, or invalid arguments

Requires macOS 26+ on Apple Silicon with Apple Intelligence enabled.
"""
