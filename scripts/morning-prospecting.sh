#!/bin/bash
# Daily 8am LinkedIn prospecting routine for Inclusify Studio
# Finds 10 new outreach contacts and logs them to the Notion CRM

LOG_DIR="/home/user/inclusify-ai-studio/logs"
LOG_FILE="$LOG_DIR/prospecting-$(date +%Y-%m-%d).log"
SCRIPT_DIR="/home/user/inclusify-ai-studio"

mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting morning prospecting run..." | tee -a "$LOG_FILE"

cd "$SCRIPT_DIR" || exit 1

claude -p "
You are running the daily morning prospecting routine for Inclusify Studio.

## YOUR GOAL
Find exactly 10 NEW outreach contacts on LinkedIn and add them to the Notion Outreach CRM. Stop at exactly 10.

## STEP 1 — CHECK THE NOTION CRM FOR EXISTING CONTACTS
Search the Notion database at page ID: 2e89c88af9ee8083bb18e9e74edb5d34
Query the database to pull the full list of existing Lead Names and LinkedIn URLs so you know who is already in the CRM. You must deduplicate against this list.

## STEP 2 — SEARCH FOR NEW CONTACTS ON LINKEDIN
Use WebSearch to find LinkedIn profiles for all three contact types below. Aim for a mix across the three categories.

**Target Contact Types:**
1. Heads of Talent, VP of Partnerships, or Founders at influencer marketing agencies — company size 5 to 50 employees
2. Influencer Marketing Managers or Brand Partnership Leads at consumer brands in: food & beverage, apparel, lifestyle, fitness, gaming, or home goods
3. Founders, Heads of Social, or Influencer Leads at PR agencies — company size 10 to 100 employees

**Search queries to rotate through (run multiple searches):**
- site:linkedin.com \"head of talent\" \"influencer marketing agency\" -WPP -IPG -Publicis
- site:linkedin.com \"VP of partnerships\" \"influencer marketing\" agency
- site:linkedin.com \"founder\" \"influencer marketing agency\" 2023 OR 2024
- site:linkedin.com \"influencer marketing manager\" \"brand partnerships\" (food OR beverage OR apparel OR lifestyle OR fitness OR gaming OR \"home goods\")
- site:linkedin.com \"brand partnerships lead\" consumer brand -Fortune500
- site:linkedin.com \"head of social\" OR \"influencer lead\" \"PR agency\"
- site:linkedin.com \"founder\" \"PR agency\" influencer social media

**Hard exclusion rules — skip any contact at:**
- Fortune 500 companies
- Holding companies: WPP, IPG, Publicis, Omnicom, Havas, Dentsu, Grey
- Hearing tech brands (Phonak, Oticon, Starkey, Widex, ReSound, Signia)
- Accessibility brands or medical brands

## STEP 3 — COLLECT CONTACT DATA
For each qualifying contact collect:
- Full name
- Company name
- Job title
- LinkedIn profile URL

## STEP 4 — DEDUPLICATE
Before adding anyone, check their name and LinkedIn URL against the existing CRM entries you pulled in Step 1. Skip anyone already in the CRM.

## STEP 5 — ADD EXACTLY 10 NEW CONTACTS TO NOTION
Add each new contact to the Notion database (page ID: 2e89c88af9ee8083bb18e9e74edb5d34) with these fields:
- Lead Name: full name
- Company: company name
- Role / Title: job title
- LinkedIn Profile: LinkedIn URL
- Lead Type: one of — Agency | Brand | PR Agency
- Outreach Status: Not Contacted
- Outreach Channel: LinkedIn
- Service Pitched: Influencer Marketing
- Notes:
  - Use 'Prompt 1' for Agency contacts
  - Use 'Prompt 2' for Brand contacts
  - Use 'Prompt 3' for PR Agency contacts

## STEP 6 — REPORT
After adding all 10, output a clean summary:
- Date run
- Total added: 10
- Breakdown by Lead Type (Agency / Brand / PR Agency)
- List each contact: Name | Company | Title | Lead Type

Stop at exactly 10. Do not add more.
" 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Prospecting run completed successfully." | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Prospecting run exited with code $EXIT_CODE." | tee -a "$LOG_FILE"
fi
