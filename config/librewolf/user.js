// Enable profile chrome/userContent.css and chrome/userChrome.css.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Allow the unsigned Gruvbox theme to be installed.
// WARNING: Disables signature enforcement for ALL add-ons in this profile.
user_pref("xpinstall.signatures.required", false);
