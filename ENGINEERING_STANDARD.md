# Engineering Documentation Standard (EDS)

**Document Control**

  Field          Value
  -------------- ------------------------------------
  Document       Engineering Documentation Standard
  Standard       EDS
  Version        1.0.0
  Status         Active
  Applies To     All Engineering Repositories
  Owner          Scott Renny
  Last Updated   July 19, 2026

------------------------------------------------------------------------

# 1. Purpose

The Engineering Documentation Standard (EDS) defines the documentation,
repository, workflow, versioning, and quality expectations for all
engineering projects within this portfolio.

Every repository shall follow this standard unless an approved exception
is documented.

------------------------------------------------------------------------

# 2. Objectives

-   Maintain consistent engineering documentation.
-   Produce repositories that are reproducible and maintainable.
-   Ensure documentation remains synchronized with implementation.
-   Establish a repeatable engineering workflow.

------------------------------------------------------------------------

# 3. Repository Structure

``` text
project-name/
├── .github/
├── assets/
├── configs/
├── docs/
├── scripts/
├── themes/
├── README.md
├── PROJECT_CHARTER.md
├── ROADMAP.md
├── BUILD_JOURNAL.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── LICENSE
└── .gitignore
```

------------------------------------------------------------------------

# 4. Required Document Structure

Major documents shall contain:

1.  Document Control
2.  Purpose
3.  Main Content
4.  Revision History
5.  Approval (where applicable)

------------------------------------------------------------------------

# 5. Repository Workflow

Every change follows this sequence:

1.  Review the repository.
2.  Identify affected files.
3.  Update all affected files completely.
4.  Validate formatting and content.
5.  Commit with a meaningful message and description.
6.  Synchronize the README if required.
7.  Proceed to the next planned task.

------------------------------------------------------------------------

# 6. Engineering Principles

-   Documentation before implementation
-   Function before appearance
-   Simplicity before complexity
-   Automation where practical
-   Security-aware design
-   Reproducibility
-   Maintainability
-   Incremental improvement

------------------------------------------------------------------------

# 7. Commit Convention

Use Conventional Commits.

  Prefix     Purpose
  ---------- ------------------------------
  docs       Documentation
  feat       New feature
  fix        Bug fix
  refactor   Internal improvement
  style      Formatting or visual changes
  test       Validation or testing
  build      Build system
  chore      Maintenance

Every change shall include: - Commit message - Commit description

------------------------------------------------------------------------

# 8. Versioning

Semantic Versioning shall be used.

-   v0.x.x --- Planning and development
-   v1.0.0 --- Initial stable release
-   v2.x.x+ --- Major enhancements

------------------------------------------------------------------------

# 9. Definition of Done

Work is complete only when:

-   Implementation is complete.
-   Documentation is updated.
-   Validation has passed.
-   Screenshots are added where applicable.
-   Build Journal is updated.
-   Changelog is updated.
-   README reflects the current state.

------------------------------------------------------------------------

# 10. Validation Checklist

Before merging:

-   Markdown renders correctly.
-   Links function.
-   Tables are aligned.
-   Repository structure is accurate.
-   Version numbers are updated.
-   Grammar and spelling have been reviewed.

------------------------------------------------------------------------

# 11. Review Process

Every major document should be reviewed for:

-   Technical accuracy
-   Consistency
-   Scope alignment
-   Readability
-   Completeness

------------------------------------------------------------------------

# 12. Revision History

  Version   Date            Description
  --------- --------------- ---------------------------------------------
  1.0.0     July 19, 2026   Initial Engineering Documentation Standard.
