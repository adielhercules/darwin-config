# Reads the local, gitignored git email file (see init.sh --email) and
# returns its trimmed contents. Hard-aborts evaluation with an actionable
# message if the file doesn't exist — this is the only enforcement point
# that can't be bypassed by going around init.sh, since day-to-day deploys
# (`just deploy`) never invoke init.sh.
{ rootPath, lib }:
let
  emailFile = "${rootPath}/.local/git-email";
in
if builtins.pathExists emailFile then
  lib.strings.trim (builtins.readFile emailFile)
else
  builtins.abort ''
    Git email not set. Expected file: ${emailFile}
    Run `./init.sh --email you@example.com` before deploying.
  ''
