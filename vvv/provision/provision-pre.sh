# Rubygems update

if [ $(gem -v|grep '^2.') ]; then

	echo "ruby-gem installed"

else

	echo "ruby-gem not installed - installing"

	apt-get install -y ruby-dev

	gem install rubygems-update

	update_rubygems

fi

# wordmove install
wordmove_install="$(gem list wordmove -i)"

if [ "$wordmove_install" = true ]; then

	echo "wordmove installed"

else

	echo "wordmove not installed"

	# once photocopier goes 1.0 we can just install base wordmove
	gem install wordmove --pre

	wordmove_path="$(gem which wordmove | sed -s 's/.rb/\/deployer\/base.rb/')"

	if [ "$(grep yaml $wordmove_path)" ]; then

		echo "can require YAML"

	else

		echo "can't require YAML"

		echo "Set require YAML"

		sed -i "7i require\ \'YAML\'" $wordmove_path

		echo "Can require YAML"

	fi
fi