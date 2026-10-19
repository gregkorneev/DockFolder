# Dock integration

## Stage A — One Dock icon (MVP 0.1)

The user pins DockFolders itself to the Dock. Clicking it shows the regular folder browser. The app implements `applicationShouldHandleReopen` to restore or bring that window forward through public app lifecycle APIs. The app does not add views to, patch, or otherwise modify the system Dock. Manual verification of repeated Dock activation remains outstanding.

## Stage B — One launcher per folder (version 0.2)

Research and prototype a small launcher app per user folder. Each launcher will send a folder identifier to DockFolders, which will activate and show that folder. Compare a custom URL scheme and XPC based on installation lifecycle, authentication, and whether DockFolders must already be running. Do not use private APIs. Document launcher creation, registration, update, and deletion before shipping this phase.

No Stage B implementation is included in the MVP.
