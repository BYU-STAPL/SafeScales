#!/bin/bash

# Create .env file in the project root
cat > .env << EOL
SUPABASE_URL=https://mqeijlaukrmcirwadrhl.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1xZWlqbGF1a3JtY2lyd2FkcmhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0ODQ5NzUsImV4cCI6MjA2NDA2MDk3NX0.rbpAhsFklDetVf0qaQ-6wJjbZnSKpRLmUsmyI8vn2wk
EOL

echo "Created .env file. Please edit it with your actual Supabase credentials." 