# PA-android-migration
A tool to migrate your Panel Attack user data on android from internal to external storage

# Tips for running as a developer / tester

If you don't use windows, you may want to create a dummy install in your appdata folder with a different name and change the `identity` inside of `conf.lua`.  
Additionally you may want to make sure that the `TESTMODE` flag in `main.lua` is set to true so that you may manually verify the migration process as the tool will otherwise simply overwrite the files that are already there.