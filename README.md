# ncurses-lyra

A simple small file lister and directory explorer.
One can use left and right arrow keys to open directories and file, or go back up to higher directory.
By default it opens files using PAGER, but files can be opened in EDITOR too using RETURN or e.

The code has been kept in one file so that the file can just be copied into one's bin folder or anywhere in the path.
This is simple ruby code, so you can edit it, or change colors or even expand this simple program.

Feel free to modify the code to your needs. You can submit patches if you feel it will help others.


I will add very little functionality to this as I use it, perhaps deleting a file, but I don't intend to let this become much larger.

File listing and sorting is done through `zsh` itself. So the `zsh` executable should be somewhere in path.

## Installation

1. 
    gem install ncurses-lyra

    You might want to alias the lyra file to a single letter.

    alias n='~/PATH/lyra.rb'

    You may also copy lyra.rb to your PATH.

2. Copying the executable file

This does depend on the `ffi-ncurses` gem by Sean Halpin.
That gem should have got installed when you installed the gem. If you did not install the gem, and just copied the lyra.rb file from the exe dir, then you will have to install that gem.

    gem install ffi-ncurses 


## Usage

Call the program using the program name.

Use ARROW keys to view a file, or enter a directory, or go up. 
Use '/' (slash) and enter a few characters and <RETURN> to see a filtered list.

There are a couple of menus with minimal options.
Tilde gives the main menu which contains a sort menu.
The toggle menu is on the equal key (=) and one can toggle hidden files, or long listing.

Some more options will be added on with time.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mare-imbrium/ncurses-lyra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
