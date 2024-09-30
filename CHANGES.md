## unreleased

### Added

- lint: Emit a warning when reporting work on an objective outside of its quarters (#306, @gpetiot)
- Allow to report time in hours (#296, @gpetiot)
- Improved okra-mode for generating reports (#289, @tmcgilchrist)

### Changed

- gen: Reorder the non-objective categories in the generated template (#290, @gpetiot)
- Improve error messages related to loading objective database (#294, @gpetiot)
- Windows: add support for %userprofile% (#295, @rikusilvola)
- legacy: Do not fail when a legacy KR is using "New KR" and "No KR" in different instances (#305, @gpetiot)

### Fixed

- lint: Fix support of KR/New KR before migration to objectives pre-week 24 (#303, @gpetiot)
- lint: Do not suggest an objective that is not valid at the time of the report (#307, @gpetiot)

## 3.1.0

### Added

- Handle markdown syntax supported by omd (#262, @gpetiot)
- lint: Allow hourly-level granularity (0.125 days) (#281, @gpetiot)

### Fixed

- stats: Take into account the workitem/objective DB (#283, @gpetiot)
- Fix parsing of titles from workitem/objective DB (#284, @gpetiot)
- team aggregate: Take into account the [-o] argument (#286, @gpetiot)

### Removed

- Disable invalid quarter warning (#279, @gpetiot)
- Disable workitem warning before week 24 (#279, @gpetiot)

## 3.0.0

### Changed

- Lint: using standardized categories before Week 24 (June 10, 2024) raises an error (#273, @gpetiot). Only Off, Hack and Misc are now valid.
- Lint: using a work-item instead of an objective raises an error starting from Week 24 (June 10, 2024) (#270, @gpetiot)
- Lint: do not fail if an objective is used for the wrong quarter (#272, @gpetiot)

## 2.1.0

### Changed

- Update the Meta standardized categories: Off, Hack and Misc (#254, @gpetiot)

### Fixed

- Fix: Use the admin_dir field in conf file to infer the path to WI/obj DB (#253, @gpetiot)
- team lint: Take WI/obj DB into account (#256, @gpetiot)
- Fix missing trailing break after format error messages (#250, @gpetiot)
- team lint: Fix file paths printed in error messages (#255, @gpetiot)
- cat: Fix formatting of code blocks (#259, @gpetiot)
- Fix the interpretation of options include-objectives and exclude-objectives (#260, @gpetiot)

## 2.0.1

### Added

- Add flycheck based checker for Emacs users (#243, @punchagan)

### Fixed

- Fix parsing of objective names containing parentheses (#246, @gpetiot)

## 2.0.0

### Changed

- Lint: Workitems in legacy reports don't cause linting to fail (#244, @gpetiot)

## 1.0.0

### Changed

- Lint: activity is now checked against objectives instead of workitems (#218, @gpetiot)
- Cat/Aggregate: generated reports use objectives instead of workitems (#218, @gpetiot)
- Use standardized categories for reporting non-engineering work time: Community, Hack, Learning, Leave, Management, Meet and Onboard (#230, @gpetiot)
- Lint: check the quarter of workitems instead of their status (#228, @gpetiot)
- Normalize error messages (#237, #239, @gpetiot)

### Added

- Allow engineers to specify the number of working days (#232, @patricoferris)
- Check that [--engineer] and [--team] are not both true (#233, @gpetiot)
- Gen: add example entries for standardized categories (#236, @gpetiot)

## 0.5.0

### Changed

- Lint: fail if the placeholder text "Work Item 1" is still present in the report (#221, @gpetiot)
- Lint: check that the total of days reported for each engineer is 5 days (#178, @gpetiot)
- No special treatment for "OKR Updates" sections in reports (#211, @gpetiot)
- Lookup okr-db in the repo directory (set by `--repo-dir`/`-C`) if `--okr-db` is not set (#210, @gpetiot)
- Make github handles clickable in repo reports (#193, #207, @gpetiot)
- Parser collects all issues instead of raising an exception (#195, @gpetiot).
  Other commands that rely on parsing weekly reports (cat, team, stats) can now be run on reports that don't pass linting, but warnings are reported.
- Improve the "Invalid time" error messages (#199, @gpetiot)
- okra team lint: only print details of invalid/missing files, or total of valid files (#200, @gpetiot)
- okra gen report: PR/issue entries formatted the same way as in engineer reports (#201, @gpetiot)
- List of projects not printed by default anymore in generated reports (#212, @gpetiot).
  Use the new option `--print-projects` to display the list.
- okra gen: Group activity items together when possible (#208, @gpetiot).
  Comments are only listed when there is no other activity on the same issue/PR.

### Fixed

- Using an empty conf should not fail, better message in case of error (#192, @gpetiot)

### Added

- stats: Add option `--show-details` to print the details of the time per engineer (#220, @gpetiot)
- Add `ocaml-re` dependency instead of using `str` (#198, @gpetiot)

### Removed

- Remove options `--include-categories` and `--include-reports` (#215, @gpetiot)

## 0.4.0

### Changed

- generate: distinguish between issue comments and PR comments (#189, @gpetiot)

### Added

- generate: add the PR merge events to the contributions (#189, @gpetiot)

### Fixed

- generate: take into account the end date of the specified period when filtering the activity (#189, @gpetiot)

## 0.3.0

### Changed

- Change granularity of time to 0.5 days (#177, @punchagan @ganeshn-gh)
- Printed reports now use undercore instead of star characters for emphasis/strong styling(#180, @gpetiot)
- The weeks are now set with the option `-w`/`--weeks` and inputs are checked (#184, @gpetiot)
- Issue/PR comments are added to activity produced by `okra generate` (#185, @gpetiot)

### Added

- Multiple weeks can now be passed to `okra team aggregate` (#182, @gpetiot)
- Add new option `--user` to `okra generate` (#185, @gpetiot)

### Fixed

- Filtering options now properly apply to `okra team aggregate` (#181, @gpetiot)

## 0.2.1

### Changed

- Lower dune version to 3.2 (#169, @gpetiot)

### Removed

- Removed unused `tls` dependency (#168, @gpetiot)

## 0.2.0

### Changed

- Rename the opam packages (#164, @gpetiot)
  + `okra` is renamed `okra-lib`
  + `okra-bin` is renamed `okra`
- Depend on get-activity >= 0.2.0 (#162, @gpetiot)

## 0.1

### Added

- Add support for filtering data on team, category and report-type (@magnuss)
- Add --version option (#99, @magnuss)
- Add support for pound prefixed KRs, aka Work Items (#124, @rikusilvola)

### Changed

- Fail with an explicit error message when --repo-dir is missing (#152, @gpetiot)
- Remove not-so-useful Unicode characters from output for a11y accessibility (#151, @shindere)
- CSV parsing updates. Include new fields for reports and links. (@magnuss)
- Update cmdliner (#103, @tmcgilchrist)
- Update gitlab (#100, @tmcgilchrist)

### Fixed

- Add missing linebreaks in the project list of activity report (#148, @gpetiot)

(changes before Jan '22 not tracked)
