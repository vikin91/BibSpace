package RedisConnectionProvider;

use Data::Dumper;
use 5.010;           #because of ~~ and say
use Try::Tiny;
use Redis;
use MooseX::Singleton;


has redisPub => (
    is      => 'ro',
    default => sub { 
    	Redis->new(server => '127.0.0.1:6379', 
                 read_timeout => 0.5, 
                 write_timeout => 2.0, 
                 reconnect => 6, 
                 every => 5000); 
   },
);
has redisSub => (
    is      => 'ro',
    default => sub { 
    	Redis->new(server => '127.0.0.1:6379', 
                 read_timeout => 0.5, 
                 write_timeout => 2.0, 
                 reconnect => 6, 
                 every => 5000); 
   },
);

no Moose;
__PACKAGE__->meta->make_immutable();
1;
