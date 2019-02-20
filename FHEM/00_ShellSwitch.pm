#####################################################################################
# $Id: 00_ShellSwitch.pm 12329 2016-10-17 00:00:40Z deespe $
#
# Usage
# 
# define <name> ShellSwitch <COMMAND> <ON> <OFF>
#
#####################################################################################

package main;

use strict;
use warnings;

use SetExtensions;

sub ShellSwitch_Initialize($)
{
  my ($hash) = @_;
  $hash->{SetFn}     = "ShellSwitch_Set";
  $hash->{DefFn}     = "ShellSwitch_Define";
  $hash->{AttrList}  = $readingFnAttributes;
}

sub ShellSwitch_Define($$)
{
  my ($hash,$def) = @_;
  my $name = $hash->{NAME};
  my @args = split("[ \t][ \t]*", $def);
  my $c = 5;
  $c = 6
    if ($args[2] !~ /^(\/|\w+:\\)/);
  return "Usage: define <name> ShellSwitch <send command e.g. /home/pi/wiringPi/433Utils/RPi_utils/codesend a 1 1> <on value e.g. 1> <off value e.g. 0>"
    if (@args < $c);
  my $cmd;
  my $max = int(@args)-2;
  for (my $i=2;$i<$max;$i+=1)
  {
    $cmd .= $args[$i]." ";
  }
  my $on    = $args[int(@args)-2];
  my $off   = $args[int(@args)-1];
  $hash->{CMD}  = $cmd;
  $hash->{ON}   = $on;
  $hash->{OFF}  = $off;
  if ($init_done && !defined $hash->{OLDDEF})
  {
    $attr{$name}{room} = "ShellSwitch";
  }
  return undef;
}

sub ShellSwitch_Set($@)
{
  my ($hash,$name,@aa) = @_;
  my ($cmd,@args) = @aa;
  my $sets = "on off";
  my $com = $hash->{CMD};
  if ($cmd eq "on")
  {
    $com .= $hash->{ON};
  }
  elsif ($cmd eq "off")
  {
    $com .= $hash->{OFF};
  }
  Log3 $name,4,"$name set @aa";
  if ($com ne $hash->{CMD})
  {
    Log3 $name,4,"$name command $com";
    if (!$hash->{InSetExtensions})
    {
      SetExtensionsCancel($hash);
      my $at = $name."_till";
      CommandDelete(undef,$at)
        if ($defs{$at});
      Log3 $name,5,"$name SetExtensionsCancel";
    }
    my $fh;
    if (open($fh,"$com|"))
    {
      my $result = undef;
      readingsBeginUpdate($hash);
      while (defined(my $line = <$fh>)) 
      {
        chomp $line;
        $result .= $line;
        Log3 $name,4,"$name command result: $line";
      }
      close $fh;
      readingsBulkUpdate($hash,"result",$result)
        if (defined $result);
      readingsBulkUpdate($hash,"state",$cmd);
      readingsEndUpdate($hash,1);
    }
    else
    {
      $hash->{STATE} = "ERROR";
    }
    return undef;
  }
  $hash->{InSetExtensions} = 1;
  my $ret = SetExtensions($hash,$sets,$name,@aa);
  delete $hash->{InSetExtensions};
  return $ret;
}

1;

=pod
=item device
=item summary    provides a simple shell switch
=item summary_DE stellt einen einfachen Schalter auf Shell Ebene zur Verf&uuml;gung
=begin html

<a name="ShellSwitch"></a>
<h3>ShellSwitch</h3>
<ul>
  Note: Take care that commands can be executed with fhem's user rights.<br>
  For commands executed with sudo please add the fhem user to the sudoers file.<br>
  <br>
  <a name="ShellSwitch_define"></a>
  <p><b>Define</b></p>
  <ul>
    <code>define &lt;name&gt; ShellSwitch &lt;command&gt &lt;on value&gt &lt;off value&gt;</code>
    <br><br>
    Defines a switch that executes a command line. This can be e.g. used to integrate wiringPi.<br>
    &lt;command&gt may contain spaces. Command is executed followed by the on/off value.
    <br>
    Examples:
    <br><br>
    <ul>
      <code>define lamp1 ShellSwitch /home/pi/wiringPi/433Utils/RPi_utils/codesend a 1 1 1 0</code><br>
    </ul>
  </ul>
  <br>
  <a name="ShellSwitch_set"></a>
  <p><b>set</b></p>
  <ul>
    <li>
      <i>off</i><br>
      send off command
    </li>
    <li>
      <i>on</i><br>
      send on command
    </li>
    <li>
      <i>blink</i>
    </li>
    <li>
      <i>intervals</i>
    </li>
    <li>
      <i>off-for-timer</i>
    </li>
    <li>
      <i>off-till</i>
    </li>
    <li>
      <i>off-till-overnight</i>
    </li>
    <li>
      <i>on-for-timer</i>
    </li>
    <li>
      <i>on-till</i>
    </li>
    <li>
      <i>on-till-overnight</i>
    </li>
    <li>
      <i>toggle</i>
    </li>
  </ul>
  <br>
  <a name="ShellSwitch_read"></a>
  <p><b>Readings</b></p>
  <ul>
    <li>
      <i>result</i><br>
      returned result (if available) of the called command
    </li>
  </ul>
</ul>

=end html
=cut
