# Home Assistant Configuration

## Setup Instructions

1. Copy `hacompanion.example.toml` to `hacompanion.toml`
2. Edit `hacompanion.toml` with your actual values:
   - Replace `YOUR_HOMEASSISTANT_TOKEN_HERE` with your Home Assistant long-lived token
   - Replace `YOUR_HA_IP` with your Home Assistant server IP
   - Replace `YOUR_LOCAL_IP` with your local machine IP

## Security Note

The actual `hacompanion.toml` file is gitignored to prevent committing sensitive tokens and IP addresses.

## Getting Your Token

1. Go to your Home Assistant instance
2. Navigate to Profile → Long-Lived Access Tokens
3. Create a new token and copy it to your config file