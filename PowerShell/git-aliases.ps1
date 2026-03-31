# removing the weird get location / content / command alias as it's fucking stupid...
Remove-Item Alias:gl -Force -ErrorAction SilentlyContinue
Remove-Item Alias:gc -Force -ErrorAction SilentlyContinue
Remove-Item Alias:gcm -Force -ErrorAction SilentlyContinue

function ga  { git add @args }
function gaa { git add . }
function gst { git status }
function gl  { git log --oneline --graph --decorate }
function gco { git checkout @args }
function gb  { git branch }
function gpl { git pull }
function gpf { git push --force-with-lease }
function gcm {
    param([string]$msg)
    git commit -m $msg
}
function gca { git commit --amend @args }
function gcan { git commit --amend --no-edit }