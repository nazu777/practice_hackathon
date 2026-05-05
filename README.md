way to git push:(solving the arrow mark error)
step 0:remove any .git inside the folder that you are trying to upload
step 1:rm -rf v2/mobile_app/.git
step 2:git add and commit


process for merging the codes in two branches
1. pull the main branch git clone -> git clone https://github.com/nazu777/practice_hackathon.git -> git fetch origin (might need)
2. go inside the folder of main branch -> cd practice_hackathon
3. then pull the child branch -> git checkout shreyansh_ui_updated_folder_name_match
4. now merge with main -> git merge origin/main (might show errors)
5. resolve the easy conflicting files that can be taken from main directly ex: generated_plugin_registrant.cc, generated_plugins.cmake, .metadata, pubspec.lock.
   execute the above function using this -> git checkout --theirs v2/mobile_app/windows/flutter/generated_plugin_registrant.cc
6. 
