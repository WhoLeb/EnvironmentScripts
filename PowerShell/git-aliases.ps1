# removing the weird get location / content / command alias as it's fucking stupid...
Remove-Item Alias:gl -Force -ErrorAction SilentlyContinue
Remove-Item Alias:gc -Force -ErrorAction SilentlyContinue
Remove-Item Alias:gcm -Force -ErrorAction SilentlyContinue

function ga  { git add @args }
function gaa { git add . }
function gs  { git status -s }
function gst { git stash @args }
function gl  { param([int]$n = 15) git log --oneline --graph --decorate -$n }
function gco { git checkout @args }
function gb  { git branch @args }
function gsw { git switch @args }
function gpl { git pull }
function gpf { git push --force-with-lease }
function gcm {
    param([string]$msg)
    git commit -m $msg
}
function gca { git commit --amend @args }
function gcan { git commit --amend --no-edit }