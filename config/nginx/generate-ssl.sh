#!/bin/bash

# Script to generate self-signed SSL certificates for development
# For production, use Let's Encrypt or proper CA-signed certificates

echo "🔐 Generating self-signed SSL certificates for development..."

# Create SSL directory if it doesn't exist
mkdir -p ssl

# Generate certificates for each subdomain
domains=("sso.aeno.tech" "mail.aeno.tech" "default")

for domain in "${domains[@]}"; do
    echo "Generating certificate for $domain..."
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/${domain}.key \
        -out ssl/${domain}.crt \
        -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Aeno Tech/OU=IT Department/CN=${domain}" \
        -extensions v3_req \
        -config <(cat <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C=ID
ST=Jakarta
L=Jakarta
O=Aeno Tech
OU=IT Department
CN=${domain}

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${domain}
DNS.2 = *.${domain}
EOF
    )
    
    echo "✅ Certificate generated for $domain"
done

echo ""
echo "🎉 All SSL certificates generated successfully!"
echo "📁 Certificates location: $(pwd)/ssl/"
echo ""
echo "⚠️  Note: These are self-signed certificates for development only."
echo "   For production, use Let's Encrypt or CA-signed certificates."