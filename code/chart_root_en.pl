#!/usr/bin/perl
use lib 'd:/dropbox/save/windows/chart_director';
use lib 'd:/dropbox/github/SimpleCall-ChartDirector/lib';
use SimpleR::Reshape;
use SimpleR::Stat;
use Encode::Locale;
use Encode;
use Data::Dumper;
use SimpleR::Reshape::ChartData;
use SimpleCall::ChartDirector;
require 'crop_img.pm';
our @head = qw/probe dom mirror ip rtt 
    probe_state probe_prov probe_isp
    ip_state ip_prov ip_isp/;
use utf8;
my @isp_list = qw/电信 联通/;

my ($k) = @ARGV;
#system("perl result_root.pl $k");
my $f = "$k/root_rtt.csv";
chart_prov_dom_cnt_stackbar_mirror($f, \@isp_list);
chart_dom_prov_rtt_multibar_isp($f, \@isp_list);
chart_prov_isp_rtt_multibar($f, \@isp_list); 
for my $isp (@isp_list){
    chart_prov_isp_rtt_bar($f, $isp);
    chart_dom_prov_rtt_bar($f, $isp);
}

sub chart_prov_isp_rtt_multibar {
    my ($f, $isp_list) = @_;
    my %isp = map { $_ => 1 } @$isp_list;
    my $isp_cast_r = cast($f, 
        charset => 'utf8', 
        skip_head => 1, 
        names => \@head, 
        id => [ 1,6,7 ],
        skip_sub => sub { exists($isp{$_[0][7]}) ? 0 : 1 }, 
        #skip_sub => sub { $_[0][7]!~/^($isp)$/ ? 1 : 0 }, 
        measure => sub { 'rtt_avg' }, 
        value => 4, 
        stat_sub => \&mean_arrayref, 
        #reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
        #write_head => 1, 
        default_cell_value => 0,
        #measure_names => \@isp_list, 

        cast_file => encode(locale => "$f.dom_prov_isp_rtt.csv"), 
        return_arrayref => 1, 
    );

    my @sort_isp_cast = sort { 
    $a->[0] cmp $b->[0]
        or 
    $b->[3] <=> $a->[3]
    } @$isp_cast_r;

    my %dom = map { $_->[0] => 1 } @sort_isp_cast;

    #my %isp = map { $_ => 1 } @$isp_list;
    for my $dom ('', keys %dom){
        my ($cast_r, %opt) = read_chart_data_dim3(\@sort_isp_cast, 
            charset => 'utf8', 
            skip_sub => sub { 
                #return 1 unless(exists $isp{$_[0][2]});
                return 0 unless($dom); 
                return $_[0][0] ne $dom ? 1 : 0 
            } , 
            label => [1], 
            legend => [2], 
            data => [3], 
            sep=> ',', 
            legend_sort => $isp_list, 
        );

        #print Dumper($cast_r);
        #my @color;
        #for my $d (@$cast_r){
        #my $c = $d<100 ? 'LightBlue1' : 
        #$d<300 ? 'Green' : 
        #$d<1000 ? 'Yellow' : 
        #'Red';
        #push @color, $c;
        #}

        s/电信/telecom/ for @{$opt{legend}};
        s/联通/unicom/ for @{$opt{legend}};
        my $dom_x = format_dom($dom);
        my $img = chart_multi_bar($cast_r, %opt,
            #color => \@color, 
            'title' => "province visit $dom_x average RTT",
            'file' => encode(locale =>"$f.prov_isp_rtt_multibar.$dom_x.png"),
            y_label_format => "{value} ms",
            #x_axis_font_angle => 90, 
            #height => 440, 
            width => 1200,
            height => 540, 
            plot_area => [ 75, 70, 1100, 400 ],
            with_legend => 1, 
        );
        #print $img, "\n";
        crop_img($img, 0, -10);
    }


}


sub chart_prov_dom_cnt_stackbar_mirror {
    my ($f, $isp_list) = @_;
    my %isp = map { $_ => 1 } @$isp_list;

    my $isp_cast_r = cast($f, 
        charset => 'utf8', 
        skip_head => 1, 
        names => \@head, 
        id => [ 1,6,7,2,8 ], #dom, prov, isp, mirror, mirror_ip_state
        #skip_sub => sub { exists $isp{$_[0][7]} ? 0 : 1 }, 
        measure => sub { 'mirror_cnt' }, 
        value => sub { 1 }, 
        stat_sub => \&sum_arrayref, 
        #reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
        #write_head => 1, 
        default_cell_value => 0,
        #measure_names => \@isp_list, 

        cast_file => encode(locale => "$f.prov_dom_cnt.csv"), 
        return_arrayref => 1, 
    );

    my @sort_isp_cast = sort { 
        $a->[0] cmp $b->[0]
            or 
        $a->[1] cmp $b->[1]
            or 
        $b->[5] <=> $a->[5]
    } @$isp_cast_r;

    my %dom = map { $_->[0] => 1 } @sort_isp_cast;

    for my $dom (keys %dom){
        my ($cast_r, %opt) = read_chart_data_dim3(\@sort_isp_cast, 
            charset => 'utf8', 
            skip_sub => sub { 
                return 1 unless(exists $isp{$_[0][2]});
                return 0 unless($dom); 
                return $_[0][0] ne $dom ? 1 : 0 
            } , 
            label => [1], 
            legend => [2,3,4], 
            data => [5], 
            sep=> ',', 
            #legend_sort => $isp_list, 
        );

        print Dumper($cast_r);
        #my @color;
        #for my $d (@$cast_r){
        #my $c = $d<100 ? 'LightBlue1' : 
        #$d<300 ? 'Green' : 
        #$d<1000 ? 'Yellow' : 
        #'Red';
        #push @color, $c;
        #}

        s/电信/telecom/ for @{$opt{legend}};
        s/联通/unicom/ for @{$opt{legend}};
        #s/无效/未知/ for @{$opt{legend}};
        my $dom_x = format_dom($dom);;

        my $img = chart_percentage_bar($cast_r, %opt,
            #color => \@color, 
            #province visit $dom_x average RTT
            'title' => "province visit $dom_x locate mirror",
            'file' => encode(locale =>"$f.prov_dom_percentage_bar.$dom_x.png"),
            #y_label_format => "{value} ms",
            #x_axis_font_angle => 90, 
            with_legend => 1, 
            width => 1350,
            height => 540, 
            plot_area => [ 75, 70, 1000, 400 ],
            legend_pos_x => 1080,
            legend_pos_y => 70,
            legend_is_vertical => 1, 
        );
        #print $img, "\n";
        crop_img($img, 0, -10);
    }
}

sub chart_dom_prov_rtt_multibar_isp {
    my ($f, $isp_list) = @_;
    my $isp_cast_r = cast($f, 
        charset => 'utf8', 
        skip_head => 1, 
        names => \@head, 
        id => [ 1,6,7 ],
        #skip_sub => sub { $_[0][7]!~/^($isp)$/ ? 1 : 0 }, 
        measure => sub { 'rtt_avg' }, 
        value => 4, 
        stat_sub => \&mean_arrayref, 
        #reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
        #write_head => 1, 
        default_cell_value => 0,
        #measure_names => \@isp_list, 

        cast_file => encode(locale => "$f.dom_prov_rtt.csv"), 
        return_arrayref => 1, 
    );

    my @sort_isp_cast = sort { 
    $a->[0] cmp $b->[0]
        or 
    $b->[3] <=> $a->[3]
    } @$isp_cast_r;

    my %prov = map { $_->[1] => 1 } grep { $_->[1] }  @sort_isp_cast;

    my %isp = map { $_ => 1 } @$isp_list;
    for my $prov ('', keys %prov){
        my ($cast_r, %opt) = read_chart_data_dim3(\@sort_isp_cast, 
            charset => 'utf8', 
            skip_sub => sub {
                return 1 unless(exists $isp{$_[0][2]});
                return 0 unless($prov); 
                return $_[0][1] ne $prov ? 1 : 0 
            } , 
            label => [0], 
            legend => [2], 
            data => [3], 
            sep=> ',', 
            legend_sort => $isp_list, 
        );

        print Dumper('中国', $cast_r, \%opt) if($prov eq '');
        print Dumper('中国xx', $cast_r, \%opt) if($prov eq '中国');

        next unless(@$cast_r);

        s/.root-servers.net// for @{$opt{label}};
        tr/[a-z]/[A-Z]/ for @{$opt{label}};
        s/电信/telecom/ for @{$opt{legend}};
        s/联通/unicom/ for @{$opt{legend}};

        my $prov_x = $prov || 'China';
        my $img = chart_multi_bar($cast_r, %opt,
            #color => \@color, 
            'title' => "$prov_x visit Root average RTT",
            'file' => encode(locale =>"$f.dom_prov_rtt_multibar.$prov_x.png"),
            y_label_format => "{value} ms",
            #x_axis_font_angle => 90, 
            #height => 420, 
            with_legend => 1, 
        );
        #print $img, "\n";
        crop_img($img, 0, -10);
    }


}

sub chart_dom_prov_rtt_bar {
    my ($f, $isp) = @_;
    my $isp_cast_r = cast($f, 
        charset => 'utf8', 
        skip_head => 1, 
        names => \@head, 
        id => [ 1,6,7 ],
        skip_sub => sub { $_[0][7]!~/^($isp)$/ ? 1 : 0 }, 
        measure => sub { 'rtt_avg' }, 
        value => 4, 
        stat_sub => \&mean_arrayref, 
        #reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
        #write_head => 1, 
        default_cell_value => 0,
        #measure_names => \@isp_list, 

        cast_file => encode(locale => "$f.dom_prov_rtt.$isp.csv"), 
        return_arrayref => 1, 
    );

    my @sort_isp_cast = sort { 
    $a->[0] cmp $b->[0]
        or 
    $b->[3] <=> $a->[3]
    } @$isp_cast_r;

    my %prov = map { $_->[1] => 1 } @sort_isp_cast;

    for my $prov ('', keys %prov){
        my ($cast_r, %opt) = read_chart_data_dim2(\@sort_isp_cast, 
            charset => 'utf8', 
            skip_sub => sub { return 0 unless($prov); return $_[0][1] ne $prov ? 1 : 0 } , 
            label => [0], 
            data => [3], 
            sep=> ',', 
        );

        my @color;
        for my $d (@$cast_r){
            my $c = $d<100 ? 'LightBlue1' : 
            $d<300 ? 'Green' : 
            $d<1000 ? 'Yellow' : 
            'Red';
            push @color, $c;
        }

        $isp=~s/电信/telecom/ ;
        $isp=~s/联通/unicom/;
        s/.root-servers.net// for @{$opt{label}};
        tr/[a-z]/[A-Z]/ for @{$opt{label}};
        my $prov_x = $prov || 'China';
        my $img = chart_bar($cast_r, %opt,
            color => \@color, 
            'title' => "$isp : $prov_x visit Root average RTT",
            'file' => encode(locale =>"$f.dom_prov_rtt_bar.$isp.$prov_x.png"),
            y_label_format => "{value} ms",
            #x_axis_font_angle => 90, 
            #height => 440, 
        );
        #print $img, "\n";
        crop_img($img, 0, -10);
    }


    #crop_img("prov_isp_recur_cnt_horizon.png", 0, -10);
}

sub chart_prov_isp_rtt_bar {
    my ($f, $isp) = @_;
    my $isp_cast_r = cast($f, 
        charset => 'utf8', 
        skip_head => 1, 
        names => \@head, 
        id => [ 1,6,7 ],
        skip_sub => sub { $_[0][7]!~/^($isp)$/ ? 1 : 0 }, 
        measure => sub { 'rtt_avg' }, 
        value => 4, 
        stat_sub => \&mean_arrayref, 
        #reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
        #write_head => 1, 
        default_cell_value => 0,
        #measure_names => \@isp_list, 

        cast_file => encode(locale => "$f.prov_isp_rtt.$isp.csv"), 
        return_arrayref => 1, 
    );

    my @sort_isp_cast = sort { 
    $b->[3] <=> $a->[3]
        or 
    $a->[0] cmp $b->[0]
    } @$isp_cast_r;

    my %dom = map { $_->[0] => 1 } @sort_isp_cast;

    for my $dom ('', keys %dom){
        my ($cast_r, %opt) = read_chart_data_dim2(\@sort_isp_cast, 
            charset => 'utf8', 
            #skip_sub => sub { $_[0][0] ne $dom ? 1 : 0 } , 
            skip_sub => sub { return 0 unless($dom); return $_[0][0] ne $dom ? 1 : 0 } , 
            label => [1], 
            data => [3], 
            sep=> ',', 
        );
        #print Dumper(\@sort_isp_cast, \%dom);
        #exit;
        my @color;
        for my $d (@$cast_r){
            my $c = $d<100 ? 'LightBlue1' : 
            $d<300 ? 'Green' : 
            $d<1000 ? 'Yellow' : 
            'Red';
            push @color, $c;
        }

        $dom_x = format_dom($dom);
        $isp=~s/电信/telecom/ ;
        $isp=~s/联通/unicom/;
        my $img = chart_bar($cast_r, %opt,
            color => \@color, 
            'title' => "$isp visit $dom_x average RTT",
            'file' => encode(locale =>"$f.prov_isp_rtt_bar.$isp.$dom_x.png"),
            y_label_format => "{value} ms",
        );
        #print $img, "\n";
        crop_img($img, 0, -10);
    }


    #crop_img("prov_isp_recur_cnt_horizon.png", 0, -10);
}

sub format_dom {
    my ($dom) = @_;
    return 'Root' unless($dom);
    $dom=~s/.root-servers.net//;
    $dom=~tr/[a-z]/[A-Z]/;
    $dom.="-Root";
    return $dom;
}
