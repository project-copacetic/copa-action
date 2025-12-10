---
name: "Copa Feature Sync"
on:
  schedule:
    - cron: "0 6 * * *"
  workflow_dispatch:
  pull_request:
    types: [labeled]
  discussion:
    types: [labeled]
permissions:
  contents: read
  actions: read
  issues: read
  pull-requests: read
  discussions: read
runs-on: ubuntu-latest
timeout-minutes: 30
description: "Continuously align copa-action with the latest Copacetic CLI release. Processes ONE release per run, oldest first."
roles: [admin, maintainer, write]
safe-outputs:
  create-discussion: # needed to create planning discussion
    title-prefix: "${{ github.workflow }}"
    category: "ideas"
  create-issue:
    title-prefix: "[copa-sync] "
    labels: [automation, needs-triage]
    max: 1
  create-pull-request:
    title-prefix: "[copa-sync] "
    labels: [automation, dependencies]
    draft: true
  add-comment:
    max: 2
    target: "*"
    discussion: true
  noop:
tracker-id: copa-sync-2024
engine:
  id: copilot
  model: claude-opus-4.5
network: defaults
steps:
  - name: Setup BATS
    uses: mig4/setup-bats@af9a00deb21b5d795cabfeaa8d9060410377686d # v1.2.0
    with:
      bats-version: ${{ env.BATS_VERSION }}
tools:
  github:
    toolsets: [default, discussions]
  edit:
  bash: [:*]
  web-fetch:
  agentic-workflows: true
env:
  COPA_REPO: project-copacetic/copacetic
  COPA_STATE_FILE: .github/agents/copa-sync-state.json
  COPA_MIN_VERSION: "v0.6.0"
  BATS_VERSION: "1.11.1"
  STATE_TEMPLATE: '{"releases":{},"last_checked":"","min_version":"v0.6.0"}'
strict: true
---

# Copa Feature Sync

## Mission

Keep this action aligned with the latest Copacetic CLI capabilities by processing **ONE release at a time**, starting from the oldest unprocessed release.

## CRITICAL: Strict Release Ordering

**YOU MUST PROCESS RELEASES IN STRICT CHRONOLOGICAL ORDER (oldest first).**

1. Start from `${{ env.COPA_MIN_VERSION }}` (v0.6.0)
2. Check if v0.6.0 has a discussion - if not, create one and STOP
3. Only after v0.6.0 is complete (all features `done` or `blocked`), move to v0.7.0
4. Repeat for each subsequent release
5. **NEVER skip ahead to newer releases**
6. **NEVER process multiple releases in one run**

## Operating Constraints

- Process exactly ONE release per workflow run - no exceptions
- Create a discussion FIRST, before any PRs or issues
- Only create PRs/issues AFTER the discussion is labeled "approved"
- Only use public information or files within this repository and `${{ env.COPA_REPO }}`
- Default to read-only actions unless a safe output provides explicit write access

## Phase Selection

**Phase 1 (Planning)** - Runs on schedule or manual trigger:
1. Fetch all releases from `${{ env.COPA_REPO }}`
2. Find the OLDEST release that doesn't have a discussion yet
3. Create a discussion for that ONE release
4. STOP and wait for human review

**Phase 2 (Implementation)** - Runs ONLY when "approved" label is added to a discussion:
1. Read the discussion that was labeled
2. Implement ONE feature from that release
3. Create a draft PR
4. Update the state file
5. STOP

Always keep `${{ env.COPA_STATE_FILE }}` updated with a `releases` object keyed by tag, each containing `discussion_url`, `last_checked` (ISO8601), `previous_tag` (for diff reference), and a `features` array where each item has `feature`, `description`, `introduced_in`, `files`, and `status` (`pending`, `in-progress`, `done`, `blocked`).

## Release Intelligence (runs every phase)

- Fetch all releases from `${{ env.COPA_REPO }}` starting from `${{ env.COPA_MIN_VERSION }}` (v0.6.0) and capture `tag_name`, `html_url`, `body`, `published_at`, and `target_commitish` for each.
- Bootstrap `${{ env.COPA_STATE_FILE }}` from `${{ env.STATE_TEMPLATE }}` if it does not exist yet.
- Process releases in ascending order (oldest first, starting with v0.6.0). Find the first release where `releases[tag_name]` either does not exist or has `pending` features remaining.
- If all releases from v0.6.0 onward are complete (all features `done` or `blocked`), emit a noop message citing the latest tag and exit.
- Clone (or fetch) `${{ env.COPA_REPO }}` locally if not present. Check out the exact `tag_name` being processed. Reuse the same checkout directory across runs when possible.

### Differential Feature Detection

When analyzing a release, identify only the **net-new features introduced in that specific version**:

1. **For v0.6.0 (baseline)**: Compare against the action's current state. Any CLI flags, environment variables, or behaviors in v0.6.0 that the action does not yet support are features for v0.6.0's backlog.
2. **For subsequent releases (v0.7.0+)**: Compare against the previous release's source tree using `git diff <prev_tag>..<current_tag>`. Only changes that appear in this diff belong to the current release's backlog.
3. **Never duplicate features**: If feature X exists in both v0.6.0 and v0.7.0, it belongs only to v0.6.0's backlog. Feature Y introduced in v0.7.0 belongs only to v0.7.0.
4. **Parse release notes for hints**: Release notes typically highlight what's new in each version; use them to validate differential detection.

Add or update feature entries under `releases[tag_name].features` so each includes:
- `feature`: Short unique name
- `description`: What changed, with links to upstream commits/docs
- `introduced_in`: The tag where this feature first appeared (for auditing)
- `files`: Target files in this repo (`action.yaml`, `README.md`, `test/test.bats`, etc.)
- `status`: `pending`, `in-progress`, `done`, or `blocked`

## Phase 1 – Planning Discussion (per release)

**Trigger**: Schedule (daily at 6am UTC) or manual `workflow_dispatch`

**Purpose**: Create a discussion for the OLDEST unprocessed release so humans can review before any code changes.

**Steps**:
1. Read `${{ env.COPA_STATE_FILE }}` to see what's already been processed
2. Sort all releases chronologically (oldest first, starting from v0.6.0)
3. Find the FIRST release where `releases[tag_name].discussion_url` does not exist in the state file
4. **If ALL releases already have discussions**: emit `noop` with message "All releases up to vX.Y.Z have discussions" and EXIT
5. **DUPLICATE CHECK (IMPORTANT)**: Before creating a discussion, search GitHub discussions for an existing discussion with title "Copa Feature Sync - <tag>". If one already exists, update the state file with its URL and emit `noop` - do NOT create a duplicate.
6. For the target release, analyze what features need to be added to copa-action
7. Create a discussion with title `Copa Feature Sync - <tag>` (e.g., `Copa Feature Sync - v0.6.0`)
8. **STOP IMMEDIATELY** after creating the discussion - do NOT proceed to Phase 2

**Discussion Body Must Include**:
- **Release Overview**: Tag, date, link to release notes
- **Features to Implement**: Table of features with status, impact, and target files
- **Questions / Risks**: Any uncertainties that need human input
- **Next Steps**: "Add the `approved` label to this discussion to trigger implementation"

Use `safe-outputs.create-discussion` to publish, then:
1. Store the URL in `${{ env.COPA_STATE_FILE }}` under `releases[tag_name].discussion_url`
2. **COMMIT the state file** to the repository so the next run knows this discussion exists
3. Then STOP - do not proceed to Phase 2

## Backlog & State Management

- Treat `${{ env.COPA_STATE_FILE }}` as the single source of truth. The `releases` object is keyed by tag name, with each release containing its own `discussion_url`, `last_checked`, `previous_tag`, and `features` array.
- Each feature entry includes `introduced_in` to record which release first added it—this prevents duplication across releases.
- The state file lives in `${{ env.COPA_STATE_FILE }}` and is committed to the repo with blank defaults so the workflow can run immediately; keep it checked in after every update.
- Ensure every feature item appears both in the state file under its release and in that release's discussion checklist so humans can track progress easily.
- When status changes, update the state file and leave a comment on the release-specific discussion so reviewers have context.
- When all features for a release reach `done` or `blocked`, consider the release complete and note this in the discussion.

## Phase 2 – Feature Delivery (single feature per run)

**Trigger**: `approved` label added to a Copa Feature Sync discussion

**Purpose**: Implement ONE feature from the approved release and create a draft PR.

**Pre-condition Check**:
- This phase ONLY runs when triggered by the `approved` label on a discussion
- Extract the release tag from the discussion title (e.g., "Copa Feature Sync - v0.6.0" → "v0.6.0")
- Verify this is the OLDEST release with pending features - if not, emit error and exit

**Steps**:
1. Read the state file under `releases[tag_name].features`
2. Find the FIRST feature with status `pending` (not `done`, `blocked`, or `in-progress`)
3. Mark that feature as `in-progress` in `${{ env.COPA_STATE_FILE }}`
4. Implement ONLY that feature - update `action.yaml`, `entrypoint.sh`, docs, and tests as needed
5. Run tests (`bats test/test.bats`) to validate
6. Create a draft PR with:
   - Title: `[copa-sync] Add <feature> from <tag>`
   - Body: Feature description, files changed, test results, link to discussion
7. Post a comment on the discussion with PR link and status
8. Update the feature status to `done` (or `blocked` if issues encountered)
9. **STOP** - do not implement additional features

**Important**: If all features for this release are complete, the next scheduled run will create a discussion for the next release in chronological order.

## Implementation Requirements

- Reflect every behavior change in `README.md` tables/examples and `test/test.bats` (or new tests) with deterministic fixtures.
- Thread new inputs through the Docker invocation in `action.yaml` and ensure defaults are honored.
- Record the commands you ran (especially tests) inside PR descriptions for reproducibility.
- Keep `.github/agents/copa-sync-state.json` valid JSON and check it in with accompanying code changes.
- Run `bats test/test.bats` after edits. If tests fail, fix them, or raise an issue explaining why they could not pass.

## Reporting & Outputs

- **Discussion**: Phase 1 uses `safe-outputs.create-discussion` to create a release-specific discussion (titled `Copa Feature Sync - <tag>`); Phase 2 uses `safe-outputs.add-comment` to provide run summaries and feature status updates on that discussion.
- **Pull Requests**: Draft PRs must map to exactly one feature from one release and include sections for release tag, files touched, validation proof, remaining gaps, and next steps.
- **Issues**: Capture upstream blockers or cross-repo follow-ups, referencing the release-specific discussion and feature entry.
- **Noop**: When no action is required, emit a noop message that cites the release tag and confirms all features are complete or that no new releases exist.

## Exit Criteria

- `${{ env.COPA_STATE_FILE }}` reflects the latest release under `releases[tag_name]` with updated timestamp and feature statuses.
- A discussion titled `Copa Feature Sync - <tag>` exists for the latest release and contains either the initial checklist (Phase 1) or a new comment from this run (Phase 2).
- Exactly one feature moved forward (to `done` or `blocked`) during Phase 2, or Phase 1 completed the discussion setup.
- Tests were executed (or a logged issue explains why they could not run).

## Fallbacks

- If GitHub API calls fail, retry after 10s, 30s, and 60s. After the third failure, raise an issue documenting the outage.
- When backlog interpretation is unclear, add questions to the discussion and exit so humans can respond.
- Use `safe-outputs.missing-tool` whenever additional tooling or permissions are required.

## Reference Links

- Copacetic CLI repo: [project-copacetic/copacetic](https://github.com/project-copacetic/copacetic)
- Action repo context: [project-copacetic/copa-action](https://github.com/project-copacetic/copa-action)
- Documentation hub: [Copacetic docs](https://project-copacetic.github.io/copacetic/)
