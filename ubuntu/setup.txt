###INITIAL CONFIG###
adduser cx
usermod -aG sudo cx

sudo apt update
sudo apt upgrade -y

sudo apt install -y git nginx certbot zsh fonts-firacode

chsh -s $(which zsh)

###SSH###
mkdir /home/cx/.ssh

###scp allowed routes from local authorized_keys, id_rsa and id_rsa.pub###
sudo systemctl restart ssh.service
sudo systemctl restart ssd

###deactivate root login via ssh###
sudo nano /etc/ssh/sshd_config

###UFW###
sudo ufw app list
sudo ufw allow 'Nginx HTTP'
sudo ufw status
# -> Nginx Full ... OpenSSH
#if inactive ->
sudo ufw enable


###OH-MY-ZSH###
$ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

#syntax-highlighting
cd ~/.oh-my-zsh/plugins &&
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git &&
echo "source ${(q-)PWD}/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ${ZDOTDIR:-$HOME}/.zshrc &&
cd ~

###STARHSIP###
curl -fsSL https://starship.rs/install.sh | bash &&
echo 'eval "$(starship init zsh)"' >> $HOME/.zshrc

###NODE###
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash &&
echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> $HOME/.zshrc

#restart and execute ->
nvm install node

###PM2###
npm install pm2@latest -g
pm2 start index.js
pm2 startup systemd
#-> get output of command and run it....sudo env PATH=$PATH:/home/cx/.nvm/versions..........
pm2 save
sudo systemctl start pm2-index

#to stop systemctl#
pm2 unstartup systemd