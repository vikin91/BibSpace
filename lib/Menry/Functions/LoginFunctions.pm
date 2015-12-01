package Menry::Functions::LoginFunctions;
use Menry::Controller::DB;
use Menry::Functions::UserObj;

use Data::Dumper;

####################################################################################
sub check_is_manager {
    my $self = shift;
    my $dbh = $self->app->db;
    my $rank = $self->users->get_rank($self->session('user'), $dbh);
    return 1 if $rank > 0;
    return 0;

}
####################################################################################
sub check_is_admin {
    my $self = shift;
    my $dbh = $self->app->db;

    my $rank = $self->users->get_rank($self->session('user'), $dbh);
    return 1 if $rank > 1;
    return 0;
}

####################################################################################

1;