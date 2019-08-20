# reproducible-mysqldump-for-vcs

Builds a reproducible XML and SQL version of schema from '`mysqldump`', so only actual schema changes trigger file changes, and file changes trigger git commits (of the SQL schema itself from `mysqldump`).

Overall, this is a simple bash script for running `mysqldump` with a bunch of regex added.  It is setup to generate both XML and SQL output files, one-file-per-format default, and makes the assumption that you are only dumping one database.

The script assumes many things.  You will want to clone/copy/modify the script directly to use.  There is no installation, configuration file, or anything of that nature.  Simply a `.sh` script that is partially ready to go.  

The file itself is commented and should be easy to navigate.  You should be able to get started by only setting a `HOST`, and setting up a `my.cnf` ([mySQL my.cnf documentation](https://dev.mysql.com/doc/refman/8.0/en/option-files.html)) file if you haven't already, and finally a `TARGET`.

The rest would be customization.

## The Idea

Something like this:

```bash
# if you really liked it you could add it as a submodule!
git clone https://github.com/abcarroll/reproducible-mysqldump-for-vcs.git script/
cp script/mysqldump-and-commit.sh .
rm -rf script/
# Now we have 'mysqldum-and-commit.sh'.  The real setup:
git init
git config user.name "Automated Schema Snapshot"
git config user.email "nobody@exmample.org"
git remote add origin ..... # OPTIONALLY, add an origin if you want it to go to a remote
man mysqldump # lots of this
editor mysql-dump-and-commit.sh # configure your heart out
crontab -e # now, add it as a cron or whatever.

./mysql-dump-and-commit.sh # and run it once to get your initial commit in
```

```text
schema-tracking$ ./mysqldump-and-commit.sh 
[full-schema.sql] ---------------------------------------
[full-schema.sql] Target File:   full-schema.sql
[full-schema.sql]   Temp File:   tmp.full-schema.sql
[full-schema.sql] Pre-Checksum:  a7ff88e682564e9f735303f453518ffcf6c8d7cecf6e206d2f1ee0ca340b9527
[full-schema.sql] Pre-LineCount: 9173
[full-schema.sql] New Checksum:  a7ff88e682564e9f735303f453518ffcf6c8d7cecf6e206d2f1ee0ca340b9527
[full-schema.sql] New LineCount: 9173
[full-schema.sql] ---------------------------------------

[full-schema.xml] ---------------------------------------
[full-schema.xml] Target File:   full-schema.xml
[full-schema.xml]   Temp File:   tmp.full-schema.xml
[full-schema.xml] Pre-Checksum:  1962bd0330a1521e577d46df058146f658d2960b55c1513cf30af03ccda3a316
[full-schema.xml] Pre-LineCount: 8300
[full-schema.xml] New Checksum:  1962bd0330a1521e577d46df058146f658d2960b55c1513cf30af03ccda3a316
[full-schema.xml] New LineCount: 8300
[full-schema.xml] ---------------------------------------
[master 103e926] Automated commit on Mon, 19 Aug 2019 21:02:42 -0400\n
 1 file changed, 16 insertions(+), 11 deletions(-)
```

And done.  Point being: **You now _should_ have a git repository that only generates commits if somebody changes your schema.**  In the above output, there were exactly 16 insertions and 11 deletions of the _real_ schema.

## Hints

- `--skip-sql` will temporarily skip SQL generation
- `--skip-xml` will temporarily skip XML generation
- `--skip-git` will temporarily skip git commit + push
- It only uses `mysqldump`, `and perl` for the main operation, `awk` for argument parsing and `sha256sum`, `cut`, and some others for more minor things like checksum generation that is only used in output.  It should run on basically any system.
- It uses perl regular expressions to convert all the "non-reproducible" parts of SQL and XML (!) to the value "-1".  The regular expressions are a little hairy looking at first, but can be extended easily in the event I've forgotten an XML attribute or SQL stanza.  Just actually break it up into more than one line.
- There is a lot more that can be done here, however this was mainly to be used as a stop-gap/alternate backup until something better can be implemented for tracking/approvals/full rollback support/etc.  In other words, this is not meant to replace "real" tools.  Only supplement them.  

## License

(C) Copyright 2019 A.B. Carroll

Available under MIT License.  See [LICENSE](LICENSE).