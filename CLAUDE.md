## Nits

- Do not use `head -NNN` or `tail -NNN`, you must always provide `head -nNNN` or `tail -nNNN` on Linux machines.
  If you forget the `-n` it will lead to an error in your pipe command.

## Git / GitHub Workflow

### Commits

- Each commit must be an **atomic, self-contained change**.                                                                                                                                                                                                                                                                                                                             The project must build at every commit.
  No scope creep per commit.                                                                                                                                                                                                                                                                                                                                                          - Hard requirement: the project compiles at every commit.
  Soft requirement: tests pass at every commit.
  It is acceptable to temporarily introduce failing tests during a larger feature or refactor, but all tests must pass before the PR is marked ready.                                                                                                                                                                                                                                 - Once a feature is complete, run the full test suite.
  Update any expected output files / golden files as part of a dedicated commit.
- The first line of the commit message is a short, scannable description that includes shorthand for the files/modules touched as a comma-separated list.
  This makes `git rebase -i` usable by reading first lines alone (e.g. `parser/{parser,lexer}, kdist/kmir.md: fix off-by-one in token scan`).
  Any file/module touched should be mentioned, as long as it is not a test directory/file or a simple utility file that is in a module already mentioned.

### Pre-PR Self-Review

Before opening a PR, inspect every diff on the branch and ask:

- Is each change actually relevant to this PR's purpose? If not, remove it or move it to a separate branch/PR.                                                                                                                                                                                                                                                                        - Are there any unintentional changes — debug prints, commented-out code, temp files, log output? Remove them.
- Is there scope creep? Anything sweeping (large refactor, unrelated cleanup) should be isolated to its own commits and ideally its own PR.
- Have tests been written for new functionality, or a regression test for any bug being fixed?
- Does any documentation need updating?
- Is the branch up-to-date with the base branch?

### Opening a PR

Use `gh pr create` (draft mode first):

```bash
gh pr create --draft --title "<short descriptive title>"
```

**PR title:** Short and descriptive.

**PR body format** (half a screen max):

```
<One paragraph describing the purpose/motivation of this change.>

**Changes:**
- <specific thing that changed>
- <specific thing that changed>
- ...

**Validation:**
- <Optional: any manual or local validation done beyond CI, e.g. "Forced test X to
  fail by inverting the assertion — confirmed it correctly caught the regression.">
```

- Always open PRs as **draft** first.
- Do not mark ready for review until: branch is up-to-date, self-review is done, CI passes, and any new tests are confirmed running in CI.
- PRs should be small and focused.
  A mix of PR types (bug fix + refactor + feature) in a single PR is a smell — split them unless the coupling is unavoidable and the commits are clearly isolated.

### Addressing Review Comments

- Acknowledge every comment explicitly on GitHub (reply "Done", "Fixed", link to a new issue, or ask for clarification).
- If a requested change is out of scope: open a new issue, link it in the comment, and do not implement it in this PR.
- Do not introduce new features after requesting review — continue on a separate branch if needed.
- After addressing: ensure CI passes, then re-request review.
- Prefer `git merge` over force-push once a PR is open — force-pushing loses GitHub comment context on the diff.

### Work Prioritization

When deciding what to work on, handle in this order:

1. PRs awaiting your review (passing CI)
2. Your open PRs with review feedback to address
3. Your draft PRs (get them to ready/passing)
4. New work

## Code Style

### Literate Programming

Err on the side of explaining the code rather than under-explaining it.
Simple algorithms with obvious structure can stand on their own — do not add noise comments that just restate what the code says.
For anything non-trivial, include an explanation of the algorithm, the key invariants, or — most importantly — *why* a design choice was made over the alternatives.
The test: if a competent reader would have to pause and reconstruct your reasoning, write it down.

### Functional Style

Prefer functional-style programming wherever the language and context allow.
Factor out pure helper functions for logic that is reused or that has a clear, nameable purpose — not for trivial single-use expressions.
Avoid state unless something genuinely needs to be tracked across the lifecycle of a program or object.
Reaching for mutable state because it is the easiest path in the moment is a smell; prefer passing values through pure functions instead.

## Automation & Tooling

- Prefer python (or whatever the project's automation language is) over manual or LLM-mediated analysis.
  Anything that can be measured or decided by a script with appropriate configuration *should* be — don't perform mechanical judgment by eye when a deterministic function can do it.
  This applies to threshold detection, cliff/inflection finding, aggregation, format checking, and pattern matching.
  The test: if a colleague could mis-judge a borderline case but a script with a stated threshold can't, write the script.
- Repeated ad-hoc queries become tool capabilities.
  If you find yourself running a similar one-liner more than twice to query the data or build a run/report, fold that functionality into the project's tool as a subcommand or module function.
  Throwaway scripts rot; tool capabilities persist and accrete improvements.
  Same applies to ad-hoc analysis you reach for repeatedly — wrap it in a `--analyze ...` flag or its own subcommand rather than re-derive it each session.
- Document new capabilities in the project's `CLAUDE.md` (or wherever the tool's usage is documented).
  When you add a subcommand, a `--flag`, or a scripted helper, write down how to invoke it in the project conventions doc so a future session can discover it without re-deriving it.
  Include the *intent* of the capability ("detects parallel-inference cliff") alongside the invocation, so it's findable by the question someone would ask, not just by its name.

## Markdown Style

- One sentence per line.
  This keeps diffs clean and makes line-level review and editing straightforward.
- Do not hard-wrap mid-sentence to hit a column limit.
- Blank lines between paragraphs; no blank lines between items in the same list.
