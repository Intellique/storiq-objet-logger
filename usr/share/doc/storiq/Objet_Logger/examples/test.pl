#!/usr/bin/perl

# Utilisation de l'objet log :
use strict;
use warnings;

use Objet_Logger;
use Data::Dumper;

my $mon_log2 = Objet_Logger->new();

$mon_log2->info("Test info 1");

$mon_log2->all("all");
$mon_log2->debug("debug");
$mon_log2->info("info");
$mon_log2->warn("warn");
$mon_log2->error("error");
$mon_log2->fatal("fatal");
$mon_log2->off("off");

$mon_log2->configure_mail( { smtp => 'mail.intellique.com', from => 'support@intellique.com',
    to => 'support@intellique.com', auth => 'PLAIN', authid => 'support@intellique.com', authpwd => 'password' } );
$mon_log2->mail( 'Oh yeah, auth!!!!!!!!!!!', 'Salut les', ' poulettes' );

$mon_log2->configure_snmp( 'localhost', '162', 'public', 'SNMPv1',
    '1.3.6.1.4.1' );
$mon_log2->snmp(
    'Oh yeah!!!!!!!!!!!', 'Salut les poulettes',
    '4.6.3',              'OCTET_STRING',
    '0'
);

exit;
