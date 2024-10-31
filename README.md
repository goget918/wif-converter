# WIF Converter Script

This script provides tools to generate a random 256-bit binary value, convert binary data to Wallet Import Format (WIF), and convert WIF back to binary data. It is useful for handling Bitcoin private keys and related cryptographic data.

## Features

- **Generate a 256-bit binary value** in a formatted text file.
- **Convert binary data to WIF**, with support for compressed and uncompressed keys.
- **Convert WIF back to binary**, saving the result in a formatted text file.

## Requirements

The script relies on the following commands:
- `xxd` – Used for hex-binary conversions.
- `openssl` – For cryptographic functions like SHA-256 hashing.
- `base58` – To encode/decode Base58 format.

Install any missing dependencies with your package manager, e.g., `apt-get` or `brew`.

## Files

- **`binary.txt`**: The file where the generated binary data is saved.
- **`wif_output.txt`**: The file where the generated WIF keys are appended.
- **`binary_<n>.txt`**: Files created from WIF conversion, containing binary values derived from WIF.

## Usage

### Script Execution

Run the script with one of the following options:

```bash
./wif.sh <command> <file>
```

**Commands**:

1. `generate` – Generate a 256-bit random binary number and save to `binary.txt`.
2. `binary_to_wif` – Convert the binary data in `<file>` to WIF format and append to `wif_output.txt`.
3. `wif_to_binary` – Convert each WIF line in `<file>` back to binary format.

### Examples

#### Generate a 256-Bit Binary File

```bash
./wif.sh generate
```

This command will create a binary.txt file with a 256-bit binary number formatted in 4 lines of 64 bits, separated by spaces every 4 bits.

#### Convert Binary to WIF

```bash
./wif.sh binary_to_wif binary.txt
```

This will convert the 256-bit binary data from binary.txt to a WIF key and append it to wif_output.txt.

#### Convert WIF to Binary

```bash
./wif.sh wif_to_binary wif_output.txt
```

Each line in wif_output.txt will be converted back to binary, saved in individual files (e.g., binary_1.txt, binary_2.txt, etc.).

### Notes

- **Binary File Format**: The binary file must contain exactly 256 bits, grouped as 4 lines of 64 bits. If the key is compressed, add `compressed` on the last line of the binary file.
- **WIF Format**: The WIF format supports both compressed and uncompressed private keys, indicated by the presence of `0x01` in the hexadecimal data before checksum calculation.

## Error Handling

The script checks for:

- Existence of required commands.
- Proper file paths and readable files.
- Correct binary length (256 bits).
- Valid checksum for WIF decoding.

## License

This script is open-source and free to use under the MIT License.
