# Tibi Lab

The tibi-lab.com website. The live pages are in `site/`, early design concepts in `mockups/`.

## Publishing
Every push to `main` that changes `site/` publishes it: the GitHub Action `.github/workflows/deploy.yml` runs `deploy.sh`, which mirrors `site/` to `public_html/` on Simply.com over encrypted FTP. Files that are not in `site/` are removed from the server (`.well-known/` is left alone).

To publish from the Mac without pushing: `./deploy.sh` (or `./deploy.sh --dry-run` to see what would change). It needs `brew install lftp`.

## Setup (once)
- **tibi-lab.com** is a Windows webhotel on Simply.com (server `nt7.unoeuro.com`); the FTP user is `tibi-lab.com`. The password is the webhotel password from Simply.com → tibi-lab.com → Loginoplysninger.
- GitHub: `gh secret set FTP_PASSWORD` (paste the password when asked).
- Mac: `security add-generic-password -a tibi-lab.com -s tibi-lab-ftp -w` (paste the password when asked).
- If you change the password at Simply, update both.
