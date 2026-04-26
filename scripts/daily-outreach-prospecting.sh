#!/bin/bash
# Daily Outreach Prospecting — runs at 8am via cron
# Finds 10 new LinkedIn contacts and logs them to the Notion Outreach CRM

LOGFILE="/home/user/inclusify-ai-studio/logs/outreach-prospecting.log"
mkdir -p "$(dirname "$LOGFILE")"

echo "=== Outreach Prospecting Run: $(date) ===" >> "$LOGFILE"

/opt/node22/bin/claude --print --dangerously-skip-permissions "$(cat <<'PROMPT'
Run the Inclusify Studio daily outreach prospecting routine. Find 10 new LinkedIn contacts and log them to the Notion Outreach CRM.

## What Inclusify Studio does
Inclusify Studio is a Deaf-led influencer marketing and social media agency. They pitch three services:
- Prompt 1 (for agencies): influencer marketing support / white-label
- Prompt 2 (for brands): influencer marketing campaigns
- Prompt 3 (for PR agencies): influencer marketing add-on services

## Step 1: Check existing CRM for duplicates FIRST
Fetch the Notion Outreach CRM database at: https://www.notion.so/2e89c88af9ee8083bb18e9e74edb5d34
Collect all existing LinkedIn URLs and names so you can skip duplicates.

## Step 2: Search LinkedIn for contacts
Use WebSearch with Google queries like:
- site:linkedin.com "head of talent" OR "VP of partnerships" OR "founder" "influencer marketing" agency
- site:linkedin.com "influencer marketing manager" OR "brand partnerships" food beverage apparel lifestyle
- site:linkedin.com "head of social" OR "influencer lead" "PR agency"

Target contact types:
- Heads of talent, VP of partnerships, or founders at influencer marketing agencies with 5-50 employees
- Influencer marketing managers or brand partnership leads at consumer brands in: food & beverage, apparel, lifestyle, fitness, gaming, or home goods
- Founders, heads of social, or influencer leads at PR agencies with 10-100 employees

AVOID: Fortune 500 companies, giant holding companies (WPP, IPG, Publicis, Omnicom, Dentsu, Havas), hearing tech brands, accessibility brands, medical/health brands.

## Step 3: Collect 10 unique contacts (not in CRM yet)
For each: full name, company, job title, LinkedIn URL, lead type (Agency/Brand/PR Agency)

## Step 4: Add all 10 to Notion CRM at https://www.notion.so/2e89c88af9ee8083bb18e9e74edb5d34
Fields per contact:
- Lead Name: full name
- Company: company name
- Role / Title: job title
- LinkedIn Profile: LinkedIn URL
- Lead Type: Agency / Brand / PR Agency
- Outreach Status: Not Contacted
- Outreach Channel: LinkedIn
- Service Pitched: Influencer Marketing
- Notes: Prompt 1 (agency), Prompt 2 (brand), Prompt 3 (PR agency)

Stop at exactly 10 new contacts.
PROMPT
)" >> "$LOGFILE" 2>&1

echo "=== Run complete: $(date) ===" >> "$LOGFILE"
