#############################################################################
# MRTG::Parse - v0.01                                                       #
#                                                                           # 
# This module parses and utilizes the logfiles produced by MRTG             #
# A full documentation is attached to this sourcecode in POD format.        #
#                                                                           #
# Copyright (C) 2005 Mario Fuerderer <mario@codehack.org>                   #
#                                                                           #
# This library is free software; you can redistribute it and/or             #
# modify it under the terms of the GNU Lesser General Public                #
# License as published by the Free Software Foundation; either              #
# version 2.1 of the License, or (at your option) any later version.        #
#                                                                           #
# This library is distributed in the hope that it will be useful,           #
# but WITHOUT ANY WARRANTY; without even the implied warranty of            #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU         #
# Lesser General Public License for more details.                           #
#                                                                           #
# You should have received a copy of the GNU Lesser General Public          #
# License along with this library; if not, write to the Free Software       #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA #
#                                                                           #
#                                    Mario Fuerderer <mario@codehack.org)   #
#                                                                           #
#############################################################################

package MRTG::Parse;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.01';


###########################################
# This subroutine receives the needed     #
# arguments and passes them to the main   #
# parser() subroutine.                    #
###########################################
sub mrtg_parse {
  my $logfile  = $_[0];
  my $period   = $_[1];

  # Start the parser and save total incoming and outgoing bytes to @array_traffic_total
  my @array_traffic_total           = &parser($logfile, $period);
  # Convert the bytes ito the right unit (probably called "prefix multiplier").
  my @array_traffic_total_unit_in   = &traffic_output($array_traffic_total[0]);
  my @array_traffic_total_unit_out  = &traffic_output($array_traffic_total[1]);
  my @array_traffic_total_unit_sum  = &traffic_output($array_traffic_total[0] + $array_traffic_total[1]);

  my @return;
  push(@return, join(' ', @array_traffic_total_unit_in));
  push(@return, join(' ', @array_traffic_total_unit_out));
  push(@return, join(' ', @array_traffic_total_unit_sum));

  return @return;
}


###########################################
# Our main subroutine, which parses the   #
# logfile with the values passed through  #
# mrtg_parse().                           # 
########################################### 
sub parser {                              
  my ($weekday, $month, $day, $time, $year) = split(/ +/, localtime(time()));
  
  my $logfile = $_[0];
  my $period  = $_[1];

  open(LOG, "$logfile") or die "Error: Could not open MRTG-Logfile ($logfile)";

  # Set any counter to zero before we start parsing.
  my $traffic_total_in  = 0;
  my $traffic_total_out = 0;
  my $last_date         = 0;
  my $counter           = 0;


  while (my $line=<LOG>) {
    # Split first column any convert the unix timestamp to something readable.
    my @column = split(/\s+/, $line);
    my $date = scalar localtime($column[0]);
    # We want to ignore the first line, because it's just the sum of the rest.
    unless ($counter == 0) {
      # Build the match-pattern
      my $pattern; 
      if ($period eq "day") {
        $pattern = ".+ $month.+$day .+$year";
      } elsif($period eq "month") {
        $pattern = ".+$month.+$year";
      } elsif($period eq "year") {
        $pattern = ".+$year";
      }
      # Check if the current line matches out pattern.
      if ($date =~ /^$pattern$/) {
        my $traffic_in  = $column[1];
        my $traffic_out = $column[2];
    
        my $time_range;
 
        unless ($last_date == 0) { 
          # Calculate the time difference between the current and the previous processd line.
          $time_range = $last_date - $column[0];
        } else {
          # Set time range to zero if its the first line.
          $time_range = 0;
        } 
        
        # Multiply the bytes with the time range.
        $traffic_total_in  += $traffic_in  * $time_range;
        $traffic_total_out += $traffic_out * $time_range;
        
        # Set the $last_date variable to the new value.
        $last_date = $column[0]; 
      }
    }
    $counter++;
  }

  my @array;
  push(@array, $traffic_total_in);
  push(@array, $traffic_total_out);
  return @array;

  close LOG;
}


###########################################
# This is just to get the right unit...   #
###########################################
sub traffic_output {
  my $bytes = $_[0];
  my $unit;
  my $total_count;
  if ($bytes < "1024") {
    $unit        = "Byte";
    $total_count = $bytes;
  } elsif ($bytes < 1024000) {
    $unit        = "KB";
    $total_count = $bytes / 1024;
  } elsif ($bytes < 1024000000) {
    $unit        = "MB";
    $total_count = $bytes / 1024000;
  } elsif ($bytes < 1024000000000) {
    $unit        = "GB";
    $total_count = $bytes / 1024000000;
  } elsif ($bytes < 1024000000000000) {
    $unit        = "TB";
    $total_count = $bytes / 1024000000000;
  } else {
    $total_count = $bytes;
  }
  my @array;
  push(@array, $total_count);
  push(@array, $unit);
  return @array;
}



__END__

=head1 MRTG::Parse

MRTG::Parse - Perl extension for parsing and utilizing the logfiles
generated by the famous MRTG Tool.

=head1 SYNOPSIS

  use strict;
  use MRTG::Parse;
  
  my $mrtg_logfile = "/var/www/htdocs/mrtg/eth0.log";
  my $period       = "day";
  
  my ($traffic_incoming, $traffic_outgoing, $traffic_sum) = MRTG::Parse::mrtg_parse($mrtg_logfile, $period);

  print "Incoming Traffic:   $traffic_incoming\n";
  print "Outgoing Traffic:   $traffic_outgoing\n";
  print "= Sum               $traffic_sum\n";
  

=head1 DESCRIPTION

This perl extension enables its users to parse and utilize the logfiles that
are generated by the famous MRTG (Multi Router Traffic Grapher) tool.
At present it can only handle three different default time periods:

        - day      (traffic generated on the current day)
	- month    (traffic generated in the current month)
	- year     (traffic generated in the current year)




=head2 EXPORT

None by default.


=head1 SEE ALSO

http://people.ee.ethz.ch/~oetiker/webtools/mrtg/ - MRTG Homepage
http://people.ee.ethz.ch/~oetiker/webtools/mrtg/mrtg-logfile.html - Description of the MRTG Logfile Format

=head1 AUTHOR

Mario Fuerderer, E<lt>mario@codehack.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Mario Fuerderer

This library is free software; you can redistribute it and/or             
modify it under the terms of the GNU Lesser General Public                
License as published by the Free Software Foundation; either             
version 2.1 of the License, or (at your option) any later version.      
                                                                       
This library is distributed in the hope that it will be useful,           
but WITHOUT ANY WARRANTY; without even the implied warranty of            
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU         
Lesser General Public License for more details.                           
                                                                          
You should have received a copy of the GNU Lesser General Public          
License along with this library; if not, write to the Free Software       
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 

=cut
