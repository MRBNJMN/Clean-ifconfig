# Clean ifconfig

## Description
Clean ifconfig parses the text from the Unix command `ifconfig` into a more user-friendly and readable format. Every network device will be displayed and parsed, in order of most to least used (determined by RX bytes). Running the program with no options produces the most useful information for a typical user. Adding an option for extended output displays all of the information that `ifconfig` has to offer.

## Files
clean-ifconfig.pl - Contains all code. Run in a Perl environment.

## Usage
Standard: `$ ./clean-ifconfig.pl`  
Extended: `$ ./clean-ifconfig.pl -e`

## Author
Ben Wheeler  
Altair Engineering  
bwheeler@altair.com
