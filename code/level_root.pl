#!/usr/bin/perl
use lib 'd:/dropbox/save/windows/chart_director';
use lib 'd:/dropbox/github/SimpleCall-ChartDirector/lib';
use lib 'D:/Dropbox/github/SimpleR-Reshape/lib';
use SimpleR::Reshape;
use SimpleR::Stat;
use Statistics::Basic qw/unbias=1 stddev variance/;
use Encode::Locale;
use Encode;
use Data::Dumper;
use SimpleR::Reshape::ChartData;
use SimpleCall::ChartDirector;
require 'crop_img.pm';
use utf8;
use strict;
use warnings;
our @HEAD = qw/probe dom mirror ip rtt 
    probe_state probe_prov probe_isp
    ip_state ip_prov ip_isp 
    rtt_status local_mirror_flag/;

our @ISP_LIST = qw/电信 联通/;
our %ISP = map { $_ => 1 } @ISP_LIST;

our	$ZONE_MIRROR_PROV_UNIQ = 1;
our $ZONE_MIRROR_R_NUM = 4;
our $ZONE_MIRROR_NUM = 6;
our @LOCAL_MIRROR_NS = qw/
f.root-servers.net.
i.root-servers.net.
j.root-servers.net.
l.root-servers.net.
/;
our %LOCAL_MIRROR_NS = map { $_ => 1 } @LOCAL_MIRROR_NS;

my ($f_d) = @ARGV;
my $f_raw="$f_d/root_raw.csv";
system(qq[perl result_hive_root.pl $f_raw]);
my $f_src = "$f_d/root_rtt.csv";

our $f_dir = $f_src;
$f_dir=~s#/[^\/\/]+$##;

split_file($f_src, id=> [ 1, 7], charset=>'utf8');
split_file($f_src, id=> [ 1 ], charset=> 'utf8');
split_file($f_src, id=> [ 7 ], charset=>'utf8');
#exit;

my $rtt_warn = mirror_rtt_warn($f_src);
my @data;
for my $f ($f_src, glob("$f_src.*")){
    next if($f=~/check.csv/);
    #next unless($f=~/l.root/);
    print "$f\n";
    my $r = check_root($f);
    $f=~s/^.*root_rtt.csv//;
    my ($ns, $isp) = $f=~/\.(.*root-servers.net.)-(.*)/;
    if(! $ns){
        ($ns) = $f=~/\.(.*.root-servers.net)$/;
        $ns = $ns ? "$ns." : 'main';
    }
    if(! $isp){
        ($isp) = $f=~/\.([^.]+)$/;
    }
    $isp ||= 'main';
    $isp = 'main' if($isp eq 'net');
    #my $isp_x = encode('utf8', decode(locale => $isp));
    #my $isp_x = encode('utf8', decode(locale => $isp));
    my $isp_x = decode(locale => $isp);

    unshift @$r, ($ns, $isp, $rtt_warn->{$ns}{$isp_x});
    push @data, $r;
}


my @final_head = qw/ns isp rtt_warn prov_uniq r_num num rtt_diff local_mirror status_good status_normal status_bad /;
write_table(\@data, file=> "$f_d/rtt_check.csv", head => \@final_head);
read_table("$f_d/rtt_check.csv", 
    write_file=> "$f_d/rtt_check_final.csv", 
    write_head => [ @final_head, 'final' ], 
    skip_head=> 1, 
    conv_sub => \&check_main_err );

sub check_main_err {
    my ($r) = @_;

    my ($ns, $rtt_warn, $rtt_diff, $local_mirror, $rtt_status_good) = 
        @{$r}[0, 2, 6, 7, 8];

    my $err =0;

    if(exists $LOCAL_MIRROR_NS{$ns} or $ns eq 'main'){
        if($rtt_status_good<0.8){
            $err += 8;
        }

        if($local_mirror< 0.6){
            $err+= 4;
        }

        if($rtt_warn>0.4){
            $err+=2;
        }
    }

    if($rtt_diff>1){
        $err+=1;
    }

    return [ @$r, $err ];
}


sub check_root {
    my ($f) = @_;

    return [ $ZONE_MIRROR_PROV_UNIQ , 
        $ZONE_MIRROR_R_NUM ,
        $ZONE_MIRROR_NUM ,
        rtt_diff_level($f),
        local_mirror_level($f),
        rtt_status_level($f),
    ];
}

sub mirror_rtt_warn {
    print "mirror rtt warn\n";
    my ($f) = @_;
    #ns, prov, isp, avg
    print "mean\n";
    my $r = cast($f, 
        names => \@HEAD, 
        charset => 'utf8', 
        skip_sub => sub {
            my $i = $_[0][7];
            ($i and (exists $ISP{$i})) ? 0 : 1 
        }, 
        id => [ 1, 6, 7,  ],
        measure => sub { 'rtt' }, 
        value => 4, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file=> 'test.csv', 
    );

    print "local remote\n";
    my %px;
    my %pin;
    for my $er (@$r){
        my ($ns, $prov, $isp, $rtt_avg) = @$er;
        my $v = exists $LOCAL_MIRROR_NS{$ns} ? 'local' : 'remote';
        push @{$px{$prov}{$isp}{$v}}, $rtt_avg;
        $pin{$prov}{$isp}{$ns} = $rtt_avg;
    }

    print "rate\n";
    my @prov_isp_warn;
    while(my ($p, $pr) = each %pin){
        while(my ($i, $xr) = each %$pr){
            my $rr = $px{$p}{$i};
            while(my ($ns, $avg) = each %$xr){
                my $rate =0;
                if(exists $LOCAL_MIRROR_NS{$ns} and $rr->{remote}){
                    my $rn = scalar(@{$rr->{remote}});
                    $rate = grep { $avg>$_ } @{$rr->{remote}};
                    $rate /= $rn;
                }
                push @prov_isp_warn, [ $ns, $p, $i, $rate ];
            }
        }
    }

    #ns, prov, isp, rate
    #write_table(\@prov_isp_warn, file => 'rtt_warn_ns_prov_isp.csv');

    my %warn;
    print "isp r\n";

    #ns isp rate
    my $isp_r = cast(\@prov_isp_warn, 
        id => [ 0, 2 ],
        measure => sub { 'isp' } , 
        value => 3, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'rtt_warn_ns_isp.csv', 
    );
    $warn{$_->[0]}{$_->[1]} = $_->[2] for @$isp_r;

    #isp, rate 
    my $iii_r = cast($isp_r, 
        skip_sub => sub { exists $LOCAL_MIRROR_NS{$_[0][0]} ? 0 : 1 }, 
        id => [ 1 ],
        measure => sub { 'mirror' } , 
        value => 2, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'rtt_warn_ns.csv', 
    );
    $warn{main}{$_->[0]} = $_->[1] for @$iii_r;

    #ns, rate
    my $mirror_r = cast($isp_r, 
        id => [ 0 ],
        measure => sub { 'mirror' } , 
        value => 2, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'rtt_warn_ns.csv', 
    );
    $warn{$_->[0]}{main} = $_->[1] for @$mirror_r;

    print "main r\n";
    my $main_r = cast($mirror_r, 
        skip_sub => sub { exists $LOCAL_MIRROR_NS{$_[0][0]} ? 0 : 1 }, 
        id => sub { 'main' },
        measure => sub { 'main' } , 
        value => 1, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'rtt_warn_main.csv', 
    );
    $warn{main}{main} = $_->[1] for @$main_r;
    #print Dumper($main_r);
    #return $main_r->[0][1];
    return \%warn;
}

sub local_mirror_level {
    print "local mirror level\n";
    my ($f) = @_;
    #ns, prov, isp, avg
    my $r = cast($f, 
        charset => 'utf8', 
        skip_sub => sub {
            my $i = $_[0][7];
            ($i and (exists $ISP{$i})) ? 0 : 1 
        }, 
        names => \@HEAD, 
        id => [ 1, 6, 7,  ],
        measure => sub { 'local' }, 
        value => 12, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'local_mirror_isp.csv', 
    );

    #ns isp avg
    my $isp_r = cast($r, 
        id => [ 0, 2 ],
        measure => sub { 'isp' } , 
        value => 3, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
    );

    my $mirror_r = cast($isp_r, 
        id => [ 0 ],
        measure => sub { 'mirror' } , 
        value => 2, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'local_mirror_mirror.csv', 
    );

    my $main_r = cast($mirror_r, 
        #skip_sub => sub { exists $LOCAL_MIRROR_NS{$_[0][0]} ? 0 : 1 }, 
        id => sub { 'main' },
        measure => sub { 'main' } , 
        value => 1, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'local_mirror_main.csv', 
    );

    return $main_r->[0][1];
}

sub rtt_diff_level {
    print "rtt diff level\n";
    my ($f) = @_;
    #ns, prov, isp, avg
    my $r = cast($f, 
        names => \@HEAD, 
        charset => 'utf8', 
        skip_sub => sub {
            my $i = $_[0][7];
            ($i and (exists $ISP{$i})) ? 0 : 1 
        }, 
        id => [ 1, 6, 7,  ],
        measure => sub { 'rtt' }, 
        value => 4, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
    );

    my $isp_r = cast($r, 
        id => [ 0, 2  ],
        measure => sub { 'isp' }, 
        value => 3, 
        stat_sub => sub { 
            my @ns = map { $_||=0; $_/100 } @{$_[0]};
            #my $x = variance(\@ns); 
            my $x = stddev(\@ns); 
            return $x->query
        } , 
        default_cell_value => 0,
        return_arrayref => 1, 
    );
    my $mirror_r = cast($isp_r, 
        id => [ 0 ],
        measure => sub { 'mirror' } , 
        value => 2, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
    );
    my $main_r = cast($mirror_r, 
        id => sub { 'main' },
        measure => sub { 'main' } , 
        value => 1, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
    );
    return $main_r->[0][1];
}

sub rtt_status_level {
    print "rtt status level\n";
    my ($f) = @_;
    my $r = cast($f, 
        names => \@HEAD, 
        id => [ 1, 6, 7,  ],
        skip_sub => sub { 
            my $i = $_[0][7];
            ($i and (exists $ISP{$i})) ? 0 : 1 
        }, 
        measure => 11, 
        measure_names => [ qw/good normal bad/ ],
        value => sub { 1 }, 
        reduce_sub => sub { my ($last, $now) = @_; return $last+$now; },
        default_cell_value => 0,
        return_arrayref => 1, 
        sep=> ',', 
        charset => 'utf8', 
    );

    # ns, prov, isp, good,normal,bad
    $_ = map_arrayref(
        $_, 
        \&calc_rate_arrayref,
        calc_col => [ 3 .. 5 ], 
        return_arrayref => 1, 
        keep_source => 1, 
    ) for @$r;

    # ns prov isp status status_rate
    my $rr = melt($r, 
        names => [ qw/ns prov isp g n b good normal bad/ ], 
        id => [ 0, 1, 2 ],
        measure => [6, 7, 8], 
        return_arrayref => 1, 
    );


    #ns, isp, status, avg
    my $isp_r = cast($rr, 
        id => [ 0, 2, 3 ],
        measure => sub { 'isp' } , 
        value => 4, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'test.isp.csv', 
        charset => 'utf8', 
    );

    #ns, status, avg
    my $mirror_r = cast($isp_r, 
        id => [ 0, 2 ],
        measure => sub { 'mirror' } , 
        value => 3, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'test.mirror.csv', 
        charset => 'utf8', 
    );


    my $main_r = cast($mirror_r, 
        id => sub { 'main' }, 
        measure => [1], 
        measure_names => [ qw/good normal bad/ ], 
        value => 2, 
        stat_sub => \&mean_arrayref, 
        default_cell_value => 0,
        return_arrayref => 1, 
        #cast_file => 'test.main.csv', 
        charset => 'utf8', 
    );

    return ($main_r->[0][1] || 0, $main_r->[0][2] || 0, $main_r->[0][3] || 0);
}
