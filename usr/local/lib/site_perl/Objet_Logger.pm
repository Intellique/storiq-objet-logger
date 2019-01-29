## ######### PROJECT NAME : ##########
##
## Objet_Logger.pm
##
## ######### PROJECT DESCRIPTION : ###
##
## Objet logger
##
## ###################################
##

#####################################
## Declaration de Package

package	Objet_Logger;

#####################################
## Declaration de librairie

use strict;

use Mail::Sender;

use Net::SNMP;
use Socket;
use Sys::Hostname;

use Log::Log4perl::Logger;

#     OFF
#     FATAL
#     ERROR
#     WARN
#     INFO
#     DEBUG
#     ALL

## ###################################
## Commandes utiles

# snmpwalk -v1 -c public -On localhost
# snmptrap -v1 -c public localhost SNMPv2-MIB::sysName localhost 6 1 0:42:00.00 SNMPv2-MIB::sysName.0 s tutu
# snmptrapd -Le -f

#####################################
## Creation de l'objet
# new ( [file] );       [$objet ou undef]
sub new {
    my ( $name, $file ) = @_;

    my $log = {};

    # Stockage du nom de l'objet
    $log->{OBJNAME} = $name;

    bless($log);

    if ($file) {
        $log->set_conf(
            \qq{
log4perl.logger                                     = DEBUG, LOG-INFO
log4perl.appender.LOG-INFO                          = Log::Log4perl::Appender::File
log4perl.appender.LOG-INFO.filename                 = $file
log4perl.appender.LOG-INFO.layout                   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG-INFO.layout.ConversionPattern = %d [%p] %m %n
}
        );
    } else {
        $log->set_conf(
            \qq{
log4perl.logger                                     = ALL, LOG-INFO, LOG-WARN

log4perl.appender.LOG-WARN                          = Log::Log4perl::Appender::Screen
log4perl.appender.LOG-WARN.stderr                   = 1
log4perl.appender.LOG-WARN.layout                   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG-WARN.layout.ConversionPattern = %d [%p] %m %n
log4perl.appender.LOG-WARN.Filter                   = FILTER-WARN
log4perl.filter.FILTER-WARN                         = Log::Log4perl::Filter::LevelRange
log4perl.filter.FILTER-WARN.LevelMin                = WARN
log4perl.filter.FILTER-WARN.LevelMax                = OFF
log4perl.filter.FILTER-WARN.AcceptOnMatch           = true

log4perl.appender.LOG-INFO                          = Log::Log4perl::Appender::Screen
log4perl.appender.LOG-INFO.stderr                   = 0
log4perl.appender.LOG-INFO.layout                   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG-INFO.layout.ConversionPattern = %d [%p] %m %n
log4perl.appender.LOG-INFO.Filter                   = FILTER-INFO
log4perl.filter.FILTER-INFO                         = Log::Log4perl::Filter::LevelMatch
log4perl.filter.FILTER-INFO.LevelToMatch            = INFO
log4perl.filter.FILTER-INFO.AcceptOnMatch           = true
}
        );

    }

    $log->debug("Objet_Logger : new : OK");
    return 0, $log;
}

#####################################
# get_conf ()         [Texte ou ""]
sub get_conf {
    my $self = shift;

    return 0, $self->{CONFIG} if ( exists $self->{CONFIG} );
    return 1, "Configuration does not exist.";
}

#####################################
# set_conf ( [file] )         [1 ou 0]
sub set_conf {
    my $self = shift;
    my $file = shift;

    if ( -f $file ) {
        $self->{CONFIG} = $file;
        Log::Log4perl->init($file);
        $self->{LOGGER} = Log::Log4perl->get_logger();

        return 0;
    }

    if ( ref $file eq "SCALAR" ) {
        $self->{CONFIG} = $$file;
        Log::Log4perl->init($file);
        $self->{LOGGER} = Log::Log4perl->get_logger();

        return 0;
    }

    return 1, "File not found or incorrect configuration string";
}

sub all {
    my $self = shift;
    $self->{LOGGER}->all(@_);
    return 0;
}

sub debug {
    my $self = shift;
    $self->{LOGGER}->debug(@_);
    return 0;
}

sub info {
    my $self = shift;
    $self->{LOGGER}->info(@_);
    return 0;
}

sub warn {
    my $self = shift;
    $self->{LOGGER}->warn(@_);
    return 0;
}

sub error {
    my $self = shift;
    $self->{LOGGER}->error(@_);
    return 0;
}

sub fatal {
    my $self = shift;
    $self->{LOGGER}->fatal(@_);
    return 0;
}

sub off {
    my $self = shift;
    $self->{LOGGER}->off(@_);
    return 0;
}

sub configure_mail {
    my $self = shift;

    my $params = shift;

    return ( 1, "bad parameters, not a hash" ) 
		unless ( ref($params) eq 'HASH' );

    $self->debug("Objet_Logger : function configure_mail : $params->{smtp}");
    $self->debug("Objet_Logger : function configure_mail : $params->{from}");
    $self->debug("Objet_Logger : function configure_mail : $params->{auth}");
    $self->debug("Objet_Logger : function configure_mail : $params->{authid}");
    $self->debug("Objet_Logger : function configure_mail : $params->{authpwd}");
    $self->debug("Objet_Logger : function configure_mail : $params->{to}");

    # check recipient
    unless ( $params->{to} ) {
        $self->error(
"Objet_Logger : configure_mail : Not enough parameters : No recipient email address found"
        );
        return 1, "Not enough parameters : No recipient email address found";
    }

    $self->{MAIL} = $params;
    return 0;
}

sub mail {
    my $self    = shift;
    my $subject = shift;
    my $message = join "", @_;

    $self->debug( "Objet_Logger : function mail : " . $subject )
      if ($subject);
    $self->debug( "Objet_Logger : function mail : " . $message )
      if ($message);

    my $sender = Mail::Sender->new(
        {
            from    => $self->{MAIL}{from},
            to      => $self->{MAIL}{to},
            subject => $subject,
            smtp    => $self->{MAIL}{smtp},
            auth    => $self->{MAIL}{auth},
            authid  => $self->{MAIL}{authid},
            authpwd => $self->{MAIL}{authpwd},
        }
    );

    unless ( ref $sender ) {
        $self->error("Error sending mail ($sender): $Mail::Sender::Error");
        return 1, $Mail::Sender::Error;
    }

    # Envoie du mail et verification du retour
    unless ( ref $sender->MailMsg( { msg => $message } ) ) {
        $self->error("Error sending mail: $Mail::Sender::Error");
        return 1, $Mail::Sender::Error;
    }

    return 0;
}

sub configure_snmp {
    my $self           = shift;
    my $host_manager   = shift;
    my $udp_port       = shift;
    my $community      = shift;
    my $version_snmp   = shift;
    my $OID_enterprise = shift;

    my %snmp;

    $self->debug("Objet_Logger : function configure_snmp : $host_manager")
      if ($host_manager);
    $self->debug("Objet_Logger : function configure_snmp : $udp_port")
      if ($udp_port);
    $self->debug("Objet_Logger : function configure_snmp : $community")
      if ($community);
    $self->debug("Objet_Logger : function configure_snmp : $version_snmp")
      if ($version_snmp);
    $self->debug("Objet_Logger : function configure_snmp : $OID_enterprise")
      if ($OID_enterprise);

# Je verifie la presence de l'OID_enterprise. Il n'est pas necessaire de vérifier la presence des autres arguments
#car le contenu des variables n'est pas vérifier
    unless ($OID_enterprise) {
        $self->error(
"Objet_Logger : configure_snmp : Not enough parameter : Enterprise OID not found."
        );
        return 1, "Not enough parameter : Enterprise OID not found.";
    }

    my $host = hostname();
    $snmp{'addr'} = inet_ntoa( scalar gethostbyname( $host || 'localhost' ) );

    $snmp{'host'}           = $host_manager;
    $snmp{'udp'}            = $udp_port;
    $snmp{'com'}            = $community;
    $snmp{'ver'}            = $version_snmp;
    $snmp{'OID_enterprise'} = $OID_enterprise;

    $self->{SNMP} = \%snmp;
    return 0;
}

sub snmp {
    my $self    = shift;
    my $message = shift;

    my $oid      = shift;
    my $oid_type = shift;
    my $spe_trap = shift;

    $self->debug("Objet_Logger : function snmp : $message")  if ($message);
    $self->debug("Objet_Logger : function snmp : $oid")      if ($oid);
    $self->debug("Objet_Logger : function snmp : $oid_type") if ($oid_type);
    $self->debug("Objet_Logger : function snmp : $spe_trap") if ($spe_trap);

# Je verifie la presence du spe_trap. Il n'est pas necessaire de vérifier la presence des autres arguments
#car le contenu des variables n'est pas vérifier
    unless ( defined $spe_trap ) {
        $self->error(
            "Objet_Logger : snmp : Not enough parameter : spe_trap not found" );
        return 1, "Not enough parameter : spe_trap not found";
    }

    $self->debug("Objet_Logger : function snmp : Net::SNMP->session");

    my ( $session, $err ) = Net::SNMP->session(
        -hostname  => $self->{SNMP}{"host"},
        -Community => $self->{SNMP}{"com"},
        -port      => $self->{SNMP}{"udp"},
        -version   => $self->{SNMP}{"ver"},
    );

    unless ( defined($session) ) {
        $self->error("Objet_Logger : snmp : Net::SNMP->session : $err");
        return 1, $err;
    }

    my @oid_value =
      ( $self->{SNMP}{'OID_enterprise'} . "." . $oid, OCTET_STRING, $message, );

    my $result = $session->trap(
        -enterprise   => $self->{SNMP}{'OID_enterprise'},
        -agentaddr    => $self->{SNMP}{"addr"},
        -generictrap  => 6,
        -specifictrap => int($spe_trap),
        -timestamp    => int( _get_uptime($self) ),
        -varbindlist  => \@oid_value,
    );

    if ( !defined($result) ) {
        $self->error( "Error sending snmp trap : ", $session->error );
        $session->close;
        return 1, $session->error;
    }

    $session->close;
    return 0;
}

## ###################################
## Methode d'uptime

sub _get_uptime {
    my $self = shift;

    # Read the uptime in seconds from /proc/uptime, skip the idle time...
    open FILE, "< /proc/uptime"
      or error( $self, "Objet_Logger : snmp : Cannot open /proc/uptime: $!" )
      and return 0;
    my ( $uptime, undef ) = split /\./, <FILE>;
    close FILE;
    return $uptime . "00";
}

#####################################

1;
