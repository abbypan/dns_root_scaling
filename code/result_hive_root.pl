#!/usr/bin/perl
use Simple::IPInfo;
use JSON;
use SimpleR::Reshape;
use Data::Dumper;
use utf8;
our @head = qw/
dom ns ns_ip probe time mirror rtt
/;

our $PROBE_INFO = get_china_probe_info();

my ($file) = @ARGV;
my $dst_file = $file;
$dst_file=~s/raw.csv$/rtt.csv/;
my %rem_mirror;
read_table($file, 
    write_file=> $dst_file, 
    sep=> ',', 
    charset=>'utf8', 
    conv_sub => sub {
        my ($r) = @_;
        my ($dom, $ns, $ns_ip, $probe, $time, $mirror, $rtt) = @$r;
        $mirror=~s/"//sg;
        return if($mirror=~/^-1$/ and $rtt=~/^-1$/);
        $rtt = $rtt % 2000;
        return if($rtt==0 or $rtt==1);

        print "($dom, $ns, $ns_ip, $probe, $time, $mirror, $rtt)\n";
        #dom ns ns_ip probe time mirror rtt
        my $ip;
        my $loc;
        if(exists $rem_mirror{$mirror}){  
            $ip = $rem_mirror{$mirror}{ip};
            $loc = $rem_mirror{$mirror}{loc};
        }else{
            $ip = ( $mirror=~/\./ ? `dig +short $mirror` : '' );
            $ip=~s/^\s+|\s+$//sg;
            my $ploc = get_ip_loc([ $ip ]);
            $ploc->{'223.220.250.33'} = { state=> '中国', prov=>'青海', isp=> '电信' };
            $ploc->{$ip}{$_} ||= 'unknown' for qw/state prov isp/;
            $loc = join(",", @{$ploc->{$ip}}{qw/state prov isp/});
            $rem_mirror{$mirror}{ip} = $ip;
            $rem_mirror{$mirror}{loc} = $loc;
        }
        return unless($PROBE_INFO->{$probe} and $PROBE_INFO->{$probe}{isp}
                and $PROBE_INFO->{$probe}{isp}=~/^(联通|电信)$/
        );
            #$rtt<150 ? 'good' : $rtt< 300 ? 'normal' : 'bad',
        return [ $probe, $ns, $mirror || 'unknown', $ip || 'unknown', $rtt, 
            @{ $PROBE_INFO->{$probe} }{qw/state prov isp/}, 
            $loc || '未知,未知,未知', 

            $rtt<100 ? 'good' : $rtt< 300 ? 'normal' : 'bad',
            $mirror=~/bei|pek/ ? 1 : 0, 
        ];
    },
);

sub get_china_probe_info {

    my %china_info = map {
        $_->{probe_id} =>
          { state => '中国', prov => $_->{state}, isp => $_->{operator} }
      }
      grep { $_->{status}==1 and $_->{operator} ne '海外' } @$info;
      print scalar(keys(%china_info)), "\n";
    return \%china_info;
}
