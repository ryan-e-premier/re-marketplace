#!/bin/bash
# Formats Claude Code JSONL transcript to readable markdown

TRANSCRIPT_FILE="$1"

if [ -z "$TRANSCRIPT_FILE" ]; then
    echo "Usage: format-transcript.sh <transcript.jsonl>"
    exit 1
fi

if [ ! -f "$TRANSCRIPT_FILE" ]; then
    echo "Error: File not found: $TRANSCRIPT_FILE"
    exit 1
fi

# Process each line and format
while IFS= read -r line; do
    type=$(echo "$line" | jq -r '.type // empty')

    case "$type" in
        "summary")
            summary=$(echo "$line" | jq -r '.summary // empty')
            if [ -n "$summary" ]; then
                echo "# $summary"
                echo ""
            fi
            ;;
        "user")
            role=$(echo "$line" | jq -r '.message.role // empty')
            is_meta=$(echo "$line" | jq -r '.isMeta // false')

            # Skip meta messages (slash command expansions)
            if [ "$is_meta" = "true" ]; then
                continue
            fi

            if [ "$role" = "user" ]; then
                content=$(echo "$line" | jq -r '
                    if .message.content | type == "string" then
                        .message.content
                    elif .message.content | type == "array" then
                        [.message.content[] |
                            if .type == "text" then .text
                            elif .type == "tool_result" then
                                if .is_error == true then
                                    "**Tool Error:** " + (.content // "")
                                else
                                    "**Tool Result:** (truncated)"
                                end
                            else empty
                            end
                        ] | join("\n")
                    else
                        empty
                    end
                ')

                # Skip empty content, system reminders, and tool results
                if [ -n "$content" ]; then
                    # Remove system reminders
                    content=$(echo "$content" | sed '/<system-reminder>/,/<\/system-reminder>/d')
                    # Clean up command messages
                    content=$(echo "$content" | sed 's/<command-message>.*<\/command-message>//')
                    content=$(echo "$content" | sed 's/<command-name>\(.*\)<\/command-name>/**Command: \1**/')
                    # Remove tool results (they're just noise)
                    content=$(echo "$content" | grep -v "^\*\*Tool Result:\*\*" | grep -v "^\*\*Tool Error:\*\*")

                    if [ -n "$(echo "$content" | tr -d '[:space:]')" ]; then
                        echo "---"
                        echo ""
                        echo "## 👤 User"
                        echo ""
                        echo "$content"
                        echo ""
                    fi
                fi
            fi
            ;;
        "assistant")
            content=$(echo "$line" | jq -r '
                if .message.content | type == "array" then
                    [.message.content[] |
                        if .type == "text" then
                            .text
                        elif .type == "tool_use" then
                            "📎 **" + .name + "**: `" + (.input.command // .input.file_path // .input.pattern // (.input | keys | .[0]) // "...") + "`"
                        else
                            empty
                        end
                    ] | join("\n\n")
                else
                    empty
                end
            ')

            if [ -n "$content" ]; then
                # Remove any system reminders that might be in assistant content
                content=$(echo "$content" | sed '/<system-reminder>/,/<\/system-reminder>/d')

                if [ -n "$(echo "$content" | tr -d '[:space:]')" ]; then
                    echo "---"
                    echo ""
                    echo "## 🤖 Assistant"
                    echo ""
                    echo "$content"
                    echo ""
                fi
            fi
            ;;
    esac
done < "$TRANSCRIPT_FILE"
