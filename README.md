OKR report aggregation tool
=======

Prototype aggregation tool and library for markdown-based OKR reports. This is work in progress.

The tool currently supports generating weekly report stubs based on Github activity (`okra generate --week=xx`), grouping data from reports per KR (`okra cat ...`) and linting existing reports to catch formatting errors (`okra lint ..`).

Each command is described in more detail below.

## Installation

With opam (remove existing okra-related pins first):

```
$ opam pin -y https://github.com/MagnusS/okra.git
```

This should install two packages; `okra` and `okra-bin`.

## Generating weekly engineer reports

A weekly report based on Github activity can be generated using the `okra generate` command. Under the hood it is using [talex5/get-activity](https://github.com/talex5/get-activity) with added markdown formatting.

The output looks like this:

```
$ okra generate --week=30
# Projects

- Improve OKRA (OKRA1)

# Last Week

- Improve OKRA (OKRA1)
  - @MagnusS (<X> days)
  - Work Item 1

# Activity (move these items to last week)

  - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
  - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
```

To prepare the final report, the work items under `Activity` should be moved to `Last week` under the right KR and time should be added. Additional information can also be added here.

```
# Projects

- Improve OKRA (OKRA1)

# Last Week

- Improve OKRA (OKRA1)
  - @MagnusS (0.5 day)
  - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
  - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
  - Meetings
```

You can also check that the final formatting is correct before submitting the report:

```
$ okra lint --engineer report.md
```

### Configuration

To generate reports this subcommand requires a Github token stored in `~/.github/github-activity-token` to be able to access your activity. New tokens can be added in your Github profile [here](https://github.com/settings/tokens). The token should only have read access - if you just want to show public activity it doesn't need access to any additional scopes. For more details, see [talex5/get-activity](https://github.com/talex5/get-activity).

If you get an HTTPS error while downloading the Github activity, TLS support is probably not compiled into cohttp/conduit. `opam install tls` should fix this.

A list of projects you are working on can be provided in the configuration file in `~/.okra/conf.yaml`, for example:

```
projects:
  - "Improve OKRA (OKRA1)"
```

More information is provided at the bottom of the README.

## Aggregating reports

`okra cat` can be used to aggregate weekly engineer or team reports in a single report. The tool will attempt to group data by project, objective and KR if these match.

The code reads data from stdin, aggregates per KR and outputs the result.

If there are unexpected warnings or errors use `okra lint` to identify and fix them.

When `--engineer` is specified, only the `Last Week` section from each report is used for input. This is useful for aggregating reports from individual engineers into a team report.

```
$ cat magnus.md patrick.md | okra cat --engineer
# Last Week

## Last Week

- Improve OKRA (OKRA1)
    - @MagnusS (0.50 days), @patricoferris (0.50 days)
    - Add output tests [#4](https://github.com/MagnusS/okra/issues/4)
    - Add support for including only specified KR IDs [#5](https://github.com/MagnusS/okra/issues/5)
    - Meetings
    - Fixing mdx
```

If `--team` is specified, everything except what is listed under `OKR Updates` is included. This is useful for aggregating reports from multiple teams (or over multiple weeks).

```
$ cat team1.md team2.md | okra cat --team
# MirageOS

## My objective

- Improve OKRA (OKRA1)
    - @MagnusS (2.00 days), @patricoferris (4.00 days)
    - Fixing lint
    - More work on parser

- Other work (KR123)
    - @Engineer1 (2.50 days)
    - Implemented the feature
```

When aggregating multiple reports `--show-time-calc` can be used to show time calculations to help with debugging:
```
$ cat report.md report2.md | okra cat --engineer --show-time-calc=true
[...]
- Improve OKRA (OKRA1)
    - + @MagnusS (0.5 day)
    - + @patricoferris (0.5 day)
    - = @MagnusS (0.50 days) @patricoferris (0.50 days)
    ...
```


Several other options are available for modifying the output format, see `okra cat --help` for details. For example, only specific KRs can be included with `--include-krs=KR123`. Time can optionally be removed with `--show-time=false`. Sections can be ignored and removed from the final output using `--ignore-sections`.

## Linting reports

`okra lint` can be used to check reports for errors. The linter will run in two phases, first checking for formatting errors then by parsing the markdown looking for inconsistencies.

For formatting errors, each error is listed with a line number and explanation. When a parsing error is found the tool will terminate and display the error with a possible solution. If an error is found, the command will exit with a non-zero exit code.

Formatting errors will look like this:
```
$ okra lint --engineer report.md
Error(s) in file report.md:

Line 7: * used as bullet point, this can confuse the parser. Only use - as bullet marker.
1 formatting errors found. Parsing aborted.
```

When encountering parsing errors:

```
$ okra lint --engineer report.md
Error(s) in file report.md:

Invalid time entry found. Format is '- @eng1 (x days), @eng2 (x days)'
Error: Time record is invalid: (MagnusS 0.5 day)
```

We currently support two types of reports; team report and engineer report. These can be specified with `--team` and `--engineer` respectively. The main difference is which sections are included or ignored in the report (see `okra lint --help` for details).

```
$ okra lint --engineer report.md
```

or 

```
$ okra lint --team report.md
```



## Report formats

These are the formats currently recognised by the tool.

General formatting requirements:
- Only use '-' for bullet points
- Use space for indentation (2 preferred)

### Engineer weekly

Engineer reports should be in the following format. Only a section called `Last week` is included by default - the rest is free form as long as it's valid markdown:

```
# Projects

- My KR (KR123)

# Last week

- My KR (KR123)
  - @engineer1 (1 day)
  - Work item 1

# Notes
...
```

The `okra generate --week=xx` command can be used to generate a stub for this report based on your Github activity and a template. To verify formatting, use `okra lint --engineer`.

### Team activity report

The expected team report format is similar, but here every section is parsed and multiple engineers may have worked on each KR. Any section called `OKR Updates` is ignored by default and may be used to propose KR changes.

```
# Project

## OKR updates

[ignored]

## Objective

- My KR (KR ID)
  - @engineer1 (1 day), @engineer2 (2 days)
  - work item 1
    - subitem
  - work item 2
```

KR ID should consist of characters followed by a number (e.g. "KR123").

If the KR doesn't have a KR ID yet (e.g. it was requested in the OKR updates section), "new KR" is recognised by the parser as a placeholder and can be used instead. If a KR with the same name is found with a proper KR ID later they will be combined.

The `okra cat` command can be used to aggregate multiple engineer reports into one team report grouped by KR.

## Okra Configuration File

You can store a `conf.yaml` file in `~/.okra` to provide the binary with extra information to help writing weekly reports, aggregating across directories etc. You don't need a configuration file, there is a default one (but it isn't particularly useful).

```yaml
# Projects are used in weekly report generation (optional)
projects:
  - "Make okra great (Plat123)"
# Locations will be used in aggregation across multiple directories (optional)
locations:
  - "/path/to/admin/dir1"
  - "/path/to/admin/dir2"
footer: |
  # Meetings
  - A recurring meeting
```

You can also provide default work items for your projects which are particularly useful for recurring tasks (e.g. meetings). For example: 

```yaml
projects:
  - title: "Make okra great (Plat123)"
    items: 
      - "Meeting with @MagnusS, @samoht"
      - "Documenting the tool"
```

There are [mdx tests](test/bin/README.md) which show the output from such a configuration file and explain in detail what the different parts do.
