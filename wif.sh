#!/bin/bash

# Define file paths for binary and WIF outputs
BINARY_OUTPUT_FILE="binary.txt"
WIF_FILE="wif_output.txt"
BINARY_FILE=""

# Check for required dependencies
for cmd in xxd openssl base58; do
    if ! command -v "$cmd" &>/dev/null; then
        printf "Error: Required command '%s' not found. Install it to proceed.\n" "$cmd" >&2
        exit 1
    fi
done

generate_binary_256bit() {
    local hex_data binary_data formatted_binary line

    # Generate 32 bytes (256 bits) of random data in hexadecimal
    hex_data=$(openssl rand -hex 32)  # Creates exactly 64 hex characters (256 bits)
    
    # Convert hexadecimal to binary, ensuring exactly 256 bits
    binary_data=""
    for ((i=0; i<${#hex_data}; i+=2)); do
        byte="${hex_data:i:2}"
        binary_data+=$(printf "%08d" "$(echo "obase=2; ibase=16; $byte" | bc 2>/dev/null)")
    done

    # Verify we have exactly 256 bits
    if [[ ${#binary_data} -ne 256 ]]; then
        printf "Error: Generated binary data is not 256 bits.\n" >&2
        return 1
    fi

    # Format binary data as 4 lines of 64 bits, 16 groups of 4 bits each line without trailing space
    formatted_binary=""
    for ((i=0; i<256; i+=64)); do
        line="${binary_data:i:64}"  # Extract 64 bits (16 groups of 4 bits)
        line=$(echo "$line" | sed 's/.\{4\}/& /g' | sed 's/ $//')  # Add space every 4 bits and remove trailing space
        formatted_binary+="$line\n"
    done

    # Write the formatted output to the file
    printf "%b" "$formatted_binary" > "$BINARY_OUTPUT_FILE"
    printf "Random binary data generated and saved to %s in the specified format.\n" "$BINARY_OUTPUT_FILE"
}


binary_to_wif() {
    local hex_data hash checksum wif is_compressed binary_content

    # Check if the specified binary file exists and is readable
    if [[ ! -f "$BINARY_FILE" || ! -r "$BINARY_FILE" ]]; then
        printf "Error: Cannot open file %s. Make sure the file exists and is readable.\n" "$BINARY_FILE" >&2
        return 1
    fi

    # Check if the last line of the binary file reads "compressed"
    if [[ $(tail -n 1 "$BINARY_FILE") == "compressed" ]]; then
        is_compressed="true"
        # Remove the last line (compression indicator) before reading binary content
        binary_content=$(head -n -1 "$BINARY_FILE" | tr -d ' \n')
    else
        is_compressed="false"
        binary_content=$(tr -d ' \n' < "$BINARY_FILE")
    fi

    # Ensure binary content is exactly 256 bits
    if [[ ${#binary_content} -ne 256 ]]; then
        printf "Error: The binary file content must be a single 256-bit binary number.\n" >&2
        return 1
    fi

    # Convert binary to hex (32-byte hex string for 256 bits)
    hex_data=$(echo "obase=16; ibase=2; $binary_content" | bc)

    # Add version byte (0x80 for mainnet)
    hex_data="80$hex_data"

    # If compressed, append "01" to hex data
    if [[ "$is_compressed" == "true" ]]; then
        hex_data="${hex_data}01"
    fi

    # Compute checksum (first 4 bytes of SHA256(SHA256))
    hash=$(echo "$hex_data" | xxd -r -p | openssl dgst -sha256 -binary | openssl dgst -sha256 -binary)
    checksum=$(echo "$hash" | xxd -p -c 8 | head -c 8)

    # Combine hex data and checksum, then encode in WIF
    wif=$(echo "$hex_data$checksum" | xxd -r -p | base58)

    # Write the WIF to the output file
    printf "%s\n" "$wif" >> "$WIF_FILE"
    printf "WIF data saved to %s\n" "$WIF_FILE"
}

wif_to_binary() {
    local wif_line hex_data main_data checksum calculated_checksum is_compressed

    # Process each line in wif_output.txt
    local line_number=1
    while read -r wif_line; do
        # Decode WIF from Base58
        hex_data=$(echo "$wif_line" | base58 -d 2>/dev/null | xxd -p -c 256 | tr -d '\n')
        if [[ -z "$hex_data" || ${#hex_data} -lt 68 ]]; then
            printf "Error: Invalid WIF format or decoding failed in line %d.\n" "$line_number" >&2
            return 1
        fi

        # Extract main data and check for compression
        main_data="${hex_data:2:-8}"
        checksum="${hex_data: -8}"
        is_compressed=""

        # If main_data has 66 hex characters and ends with "01", it's compressed
        if [[ ${#main_data} -eq 66 && "${main_data: -2}" == "01" ]]; then
            main_data="${main_data:0:64}"  # Remove the "01" suffix
            is_compressed="compressed"
        fi

        # Convert to binary
        binary_data=$(echo "$main_data" | xxd -r -p | xxd -b -c 1 | awk '{printf "%s", $2}')
        formatted_binary=""
        for ((i=0; i<256; i+=64)); do
            line="${binary_data:i:64}"                # Extract 64 bits (16 groups of 4 bits)
            line=$(echo "$line" | sed 's/.\{4\}/& /g' | sed 's/ $//') # Add space every 4 bits and remove trailing space
            formatted_binary+="$line\n"
        done

        # Write binary output with compression status if compressed
        printf "%b" "$formatted_binary" > "binary_${line_number}.txt"
        if [[ "$is_compressed" == "compressed" ]]; then
            echo "compressed" >> "binary_${line_number}.txt"
        fi

        printf "Binary data from line %d saved to binary_%d.txt\n" "$line_number" "$line_number"
        ((line_number++))
    done < "$WIF_FILE"
}

# Main function to orchestrate the script's flow
main() {
    local action="$1"
    local file="$2"

    BINARY_FILE="$file"

    case "$action" in
        generate)
            generate_binary_256bit
            ;;
        binary_to_wif)
            binary_to_wif
            ;;
        wif_to_binary)
            wif_to_binary
            ;;
        *)
            printf "Usage: %s {generate|binary_to_wif|wif_to_binary}\n" "$0" >&2
            exit 1
            ;;
    esac
}

main "$@"
