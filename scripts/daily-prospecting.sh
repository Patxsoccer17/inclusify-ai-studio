#!/usr/bin/env bash
# Daily LinkedIn prospecting routine for Inclusify Studio
# Runs at 8am via cron. Finds 10 new outreach contacts and logs them to Notion CRM.

set -euo pipefail

LOGFILE="/home/user/inclusify-ai-studio/logs/prospecting-$(date +%Y-%m-%d).log"
mkdir -p "$(dirname "$LOGFILE")"

echo "[$(date)] Starting daily prospecting run..." | tee -a "$LOGFILE"

claude --dangerously-skip-permissions -p "
You are running the daily Inclusify Studio LinkedIn prospecting routine. Today is $(date +%Y-%m-%d).

TASK: Find exactly 10 new outreach contacts for Inclusify Studio and log them to the Notion Outreach CRM.

STEP 1 — RESEARCH: Search the web for LinkedIn profiles matching these criteria:

Target types:
- Heads of Talent, VP of Partnerships, or Founders at influencer marketing agencies with 5–50 employees
- Influencer Marketing Managers or Brand Partnership Leads at consumer brands in: food & beverage, apparel, lifestyle, fitness, gaming, or home goods
- Founders, Heads of Social, or Influencer Leads at PR agencies with 10–100 employees

Avoid: Fortune 500 companies, WPP / IPG / Publicis / Omnicom holding companies, hearing tech brands, accessibility brands, medical brands.

For each contact collect: full name, company, job title, LinkedIn URL.

STEP 2 — DEDUPLICATE: Before adding anyone, fetch the Notion Outreach CRM at this URL to check for existing contacts:
https://www.notion.so/2e89c88af9ee8083bb18e9e74edb5d34
Use the view URL for the All Leads view. Skip any contact whose name OR company already appears in the CRM.

STEP 3 — LOG: Add exactly 10 new (non-duplicate) contacts to the Notion Outreach CRM database (data source ID: 2e89c88a-f9ee-813c-96fe-000b21385572) with these fields:
- Lead Name: full name
- Company: company name
- Role / Title: job title
- LinkedIn Profile: LinkedIn URL
- Lead Type: Agency | Brand | PR Agency
- Outreach Status: Not Contacted
- Outreach Channel: LinkedIn
- Service Pitched: Influencer Marketing
- Notes: 'Prompt 1' for agencies, 'Prompt 2' for brands, 'Prompt 3' for PR agencies — plus 1-2 sentences of context about why they are a good fit.

Stop at exactly 10 new contacts. Confirm how many were added at the end.
" 2>&1 | tee -a "$LOGFILE"

echo "[$(date)] Prospecting run complete." | tee -a "$LOGFILE"
