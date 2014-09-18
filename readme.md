# Clean ifconfig

## Description
Clean ifconfig parses the text from the Unix command `ifconfig` into a more user-friendly and readable format. Every network device will be displayed and parsed, in order of most to least used (determined by RX bytes). Running the program with no options produces the most useful information for a typical user. Adding an option for extended output displays all of the information that `ifconfig` has to offer.

## Files
clean-ifconfig.pl - Contains all code. Run in a Perl environment.

## Usage
Standard: `$ ./clean-ifconfig.pl`  
Extended: `$ ./clean-ifconfig.pl -e`  
Help: `$ ./clean-ifconfig.pl -h`

## Known Issues
The RegEx to pull text after `Link encap:` takes a shortcut. There's at least two possibilities for this output:

    Link encap:Ethernet HWaddr ... \n
    or
    Link encap:Local Loopback \n

Right now, the solution simply looks for `Ethernet|Local Loopback` and captures it accordingly. A better solution would be to capture the actual text (either one or two words) with the condition that HWaddr may or may not follow.

## Author
Ben Wheeler  
Altair Engineering  
bwheeler@altair.com
