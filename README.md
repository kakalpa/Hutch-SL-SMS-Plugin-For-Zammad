
# [Hutch](https://hutch.lk/) SMS Plugin For [Zammad](https://zammad.org)  

### This is a Plugin for [Zammad](https://zammad.org) Helpdesk which provide support to Hutch SMS gateway


### ***Usage***

- Download the .zmp file (Pre Packaged Version of the Addon)
- Go to Zammad Settings <img src="https://raw.githubusercontent.com/FortAwesome/Font-Awesome/6.x/svgs/solid/gear.svg" width="20" height="20" alt="gear icon"> -> Packages
- Choose File -> Choose the File -> Click Install Package.

- After Installing it is recommended to Run Below Commands On your Zammad Instance.
- ```zammad run rake zammad:package:migrate```
- ```zammad run rake assets:precompile```
- ```systemctl restart zammad```
- After all this you will be able to See Hutch as a Option in SMS -> Notification


Source Could be found in [Here](hutch_withdebug.rb). Feel Free to Do modifications. This Code can be taken as a sample to any other OAuth Enable SMS Providers as well. 

After modification if you want to re package the add on please refer [this](https://lcx.wien/blog/how-to-create-your-custom-zammad-package/) article.