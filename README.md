# Eve

![SwiftGen's Eve logo](logo/logo-256.png)

This repository allows you to automate the tasks necessary to develop SwiftGen.

In detail, the aim is to be able to do the following tasks from a centralised location using a centralized Rakefile:

* Clone all SwiftGen repositories.
* Check the status of each repository globally, like:
  * Scanning for dirty working copies
  * Listing all open issues and PRs accross all repositores
  * …
* Propagate consistent settings accross all repositories, like:
  * Ensure all repos use the same `Dangerfile`
  * Ensure all repos use the same `.swiftlint.yml`
  * …
* Create a new release of SwiftGen
  * Ensuring the CHANGELOGs of all repos are up-to-date
  * Ensuring the CHANGELOGs of all repos are formatted properly and reference each other properly
  * Tagging all repos
  * Preparing a ZIP containing the built release for CocoaPods or ZIP distribution
  * Prepare a Homebrew release, test it and make a PR to Homebrew
  * …

> Note that not all those tasks are implemented _yet_, but that's what we aim for for this repo.
