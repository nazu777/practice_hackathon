way to git push:(solving the arrow mark error)
step 0:remove any .git inside the folder that you are trying to upload
step 1:rm -rf v2/mobile_app/.git
step 2:git add and commit


process for merging the codes in two branches
1. pull the main branch git clone -> git clone https://github.com/nazu777/practice_hackathon.git -> git fetch origin (might need)
2. go inside the folder of main branch -> cd practice_hackathon
3. then pull the child branch -> git checkout shreyansh_ui_updated_folder_name_match
4. now merge with main -> git merge origin/main (might show errors)
5. resolve the easy conflicting files that can be taken from main directly ex: generated_plugin_registrant.cc, generated_plugins.cmake, .metadata, pubspec.lock. swift
   execute the above function using this -> git checkout --theirs v2/mobile_app/windows/flutter/generated_plugin_registrant.cc
6. the source control is the block <img width="1920" height="1020" alt="image" src="https://github.com/user-attachments/assets/dd670841-fc5f-49c3-9051-41f2be0447c7" /> if here, u can see the files that are in conflict with the two branches, so once u click it u can resolve by giving both versions to ai and taking the integrated version. Click the + icon once the changes have been made to a file, there is resolve by merge editor too -> left one represents main branch and right represents the child branch.
Note: the changes will still show the errors until all the files are resolved and commited (that doesnt mean the changes aint saved)
shutting down of pc will not loose the data of the chages made. (undo the changes made).
after shut down we can get to the current state by <img width="1920" height="1020" alt="image" src="https://github.com/user-attachments/assets/cbba5e06-81db-4da7-b6b8-2e0fc2d5a8d5" />
7. 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 -> token of nazu777. it will expire in 30 days -> https://github.com/settings/tokens -> this will be used during git push.
