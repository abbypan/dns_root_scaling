#!/usr/bin/perl
use Simple::IPInfo;
our @head = qw/probe dom mirror ip rtt 
    probe_state probe_prov probe_isp
    ip_state ip_prov ip_isp/;
    use Data::Dumper;

#my $ip = '223.220.250.33';
#my $ip = '202.38.64.10';
#my $ploc = get_ip_loc([ $ip ]);
#print Dumper($ploc);
#exit;


my ($key) = @ARGV;
my @files = glob("$key/result_*");
my %rem_mirror_ip;
my %rem_mirror_loc;

     my @tietong = qw/
222.45.45.59
222.44.83.6
222.42.112.145
61.236.129.147
211.98.176.7 
222.34.30.41
123.81.249.98
/;

open my $fhw, '>:utf8', "$key/root_rtt.csv";
print $fhw join(",", @head), "\n";

for my $f (@files){
    my ($probe) = $f=~/^.*result_(.+)$/;

    next if(grep { $_ eq $probe} @tietong); #铁通

    if(! exists $rem_mirror_loc{$probe}){
        my $ploc = get_ip_loc([ $probe ]);

        $ploc->{'223.220.250.33'} = { 
            state=> '中国', prov=>'青海', isp=> '电信' };
        $rem_mirror_loc{$probe} = join(",", @{$ploc->{$probe}}{qw/state prov isp/});
    }
    
    open my $fh,'<', $f;
    while(<$fh>){
        chomp;
        s/^\s+|\s+$//g;
        my ($dom, $mirror, $rtt) = split /\s+/;
        next unless($rtt);

        my $ip = exists $rem_mirror_ip{$mirror} ? 
            $rem_mirror_ip{$mirror} :
            ( $mirror=~/\./ ? `dig +short $mirror` : '' );
        $ip=~s/^\s+|\s+$//sg;
        $rem_mirror_ip{$mirror} = $ip;
    if(! exists $rem_mirror_loc{$ip}){
        my $ploc = get_ip_loc([ $ip ]);
        $ploc->{'223.220.250.33'} = { 
            state=> '中国', prov=>'青海', isp=> '电信' };
        $rem_mirror_loc{$ip} = join(",", @{$ploc->{$ip}}{qw/state prov isp/});
    }


        print $fhw join(",", $probe,
                $dom,$mirror,$ip,$rtt,
                $rem_mirror_loc{$probe} || '未知,未知,未知',
                $rem_mirror_loc{$ip} || '未知,未知,未知'
            ), "\n";
    }
    close $fh;
}
close $fhw;
