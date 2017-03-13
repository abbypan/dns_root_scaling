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

my ($f) = @ARGV;
#my $f = "$k/root_rtt.csv";
#system("perl result_root.pl $k") unless(-f $f);
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

        my $dom_x = $dom || 'root';
        my $img = chart_multi_bar($cast_r, %opt,
            #color => \@color, 
            'title' => "各省 访问 $dom_x 平均访问时延",
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

#sub chart_prov_isp_rtt_multibar {
    #my ($f, $isp_list) = @_;
    #my %isp = map { $_ => 1 } @$isp_list;
    #my $isp_cast_r = cast($f, 
        #charset => 'utf8', 
        #skip_head => 1, 
        #names => \@head, 
        #id => [ 1,6,7 ],
        #skip_sub => sub { exists($isp{$_[0][7]}) ? 0 : 1 }, 
        #measure => sub { 'rtt_avg' }, 
        #value => 4, 
        #stat_sub => \&mean_arrayref, 
        ##reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
        ##write_head => 1, 
        #default_cell_value => 0,
        ##measure_names => \@isp_list, 

        #cast_file => encode(locale => "$f.prov_isp_rtt.main.csv"), 
        #return_arrayref => 1, 
    #);

    #my @sort_isp_cast = sort { 
    #$b->[3] <=> $a->[3]
        #or 
    #$a->[0] cmp $b->[0]
        #or 
    #$a->[1] cmp $b->[1]
    #} @$isp_cast_r;

    #my %dom = map { $_->[0] => 1 } @sort_isp_cast;

    #for my $dom ('', keys %dom){
        #my ($cast_r, %opt) = read_chart_data_dim3(\@sort_isp_cast, 
            #charset => 'utf8', 
            #skip_sub => sub { $_[0][0] ne $dom ? 1 : 0 } , 
            ##skip_sub => sub { return 0 unless($dom); return $_[0][0] ne $dom ? 1 : 0 } , 
            #label => [1], 
            #legend => [2], 
            #data => [3], 
            #sep=> ',', 
        #);
        ##print Dumper(\@sort_isp_cast, \%dom);
        ##exit;
        #my @color= qw/Green Yellow/;
        ##for my $d (@$cast_r){
            ##my $c = $d<100 ? 'LightBlue1' : 
            ##$d<300 ? 'Green' : 
            ##$d<1000 ? 'Yellow' : 
            ##'Red';
            ##push @color, $c;
        ##}

        #$dom_x = $dom || 'root';
        #my $img = chart_bar($cast_r, %opt,
            ##color => \@color, 
            #'title' => "各省份 访问 $dom_x 平均访问时延",
            #'file' => encode(locale =>"$f.prov_isp_rtt_multibar.$dom_x.png"),
            #y_label_format => "{value} ms",
        #);
        ##print $img, "\n";
        #crop_img($img, 0, -10);
    #}


    ##crop_img("prov_isp_recur_cnt_horizon.png", 0, -10);
#}

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

        #s/无效/未知/ for @{$opt{legend}};
        my $dom_x = $dom || 'root';
        my $img = chart_percentage_bar($cast_r, %opt,
            #color => \@color, 
            'title' => "各省 访问 $dom_x 命中的镜像",
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

        #print Dumper($cast_r);
        #my @color;
        #for my $d (@$cast_r){
        #my $c = $d<100 ? 'LightBlue1' : 
        #$d<300 ? 'Green' : 
        #$d<1000 ? 'Yellow' : 
        #'Red';
        #push @color, $c;
        #}
        next unless(@$cast_r);

        s/.root-servers.net// for @{$opt{label}};

        my $prov_x = $prov || '中国';
        my $img = chart_multi_bar($cast_r, %opt,
            #color => \@color, 
            'title' => "$prov_x 访问 root 平均访问时延",
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

        s/.root-servers.net// for @{$opt{label}};
        my $prov_x = $prov || '中国';
        my $img = chart_bar($cast_r, %opt,
            color => \@color, 
            'title' => "$prov_x $isp 访问 root 平均访问时延",
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

        $dom_x = $dom || 'root';
        my $img = chart_bar($cast_r, %opt,
            color => \@color, 
            'title' => "各省份 $isp 访问 $dom_x 平均访问时延",
            'file' => encode(locale =>"$f.prov_isp_rtt_bar.$isp.$dom_x.png"),
            y_label_format => "{value} ms",
        );
        #print $img, "\n";
        crop_img($img, 0, -10);
    }


    #crop_img("prov_isp_recur_cnt_horizon.png", 0, -10);
}

#our @color = qw/Red1 Yellow Green LightBlue1 Purple LightGoldenrod/;
#our @isp_list= qw/电信 联通 移动 铁通/;
#our @isp_en =  qw/tel cnc mob tie/;

#my $s = stat_prov_isp();
#chart_isp_to_prov_bar($s);
#chart_prov_to_isp_multi_bar($s);

#my @prov_list = qw/北京 广东 上海 山东 福建 四川 陕西 浙江 江苏/;
#chart_prov_to_isp_bar_cnt($s, $_) for @prov_list;
#chart_prov_to_isp_bar_rate($s, $_) for @prov_list;

#sub chart_prov_to_isp_bar_rate {
#my ($s, $prov) = @_;
##my @sort_s = grep { $_->[0] eq $prov } @$s;
#my ($r, %opt) = read_chart_data_dim2(
##\@sort_s, 
#$s, 
##skip_head=> 1, 
#skip_sub => sub { $_[0][0] ne $prov ? 1 : 0 }, 
#label => [1], 
#data => [4], 
#sep=> ',', 
#charset => 'utf8', 
#label_sort => \@isp_list, 
##legend_sort => $label_sort, 
#);
#my $f = encode(locale => "isp_recur_$prov.rate.png");
#chart_bar($r, %opt,
#'title' => " $prov 开放递归比例（运营商）",
#'file' => $f,
#with_data_label => 1,
#data_label_format => '{value}%', 
#y_label_format => '{value}%',
#color => \@color, 
#);
#crop_img($f, 0, -10);

#}

#sub chart_prov_to_isp_bar_cnt {
#my ($s, $prov) = @_;
##my @sort_s = grep { $_->[0] eq $prov } @$s;
#my ($r, %opt) = read_chart_data_dim2(
##\@sort_s, 
#$s, 
##skip_head=> 1, 
#skip_sub => sub { $_[0][0] ne $prov ? 1 : 0 }, 
#label => [1], 
#data => [3], 
#sep=> ',', 
#charset => 'utf8', 
#label_sort => \@isp_list, 
##legend_sort => $label_sort, 
#);
#my $f = encode(locale => "isp_recur_$prov.cnt.png");
#chart_bar($r, %opt,
#'title' => " $prov 开放递归个数（运营商）",
#'file' => $f,
#with_data_label => 1,
#color => \@color, 
#);
#crop_img($f, 0, -10);

#}

#sub stat_prov_isp {
#my $n = stat_prov_isp_cnt('china_recur.csv');
#my @sort_n = sort { $a->[0] cmp $b->[0] or $a->[1] cmp $b->[1] } @$n;
#my %recur_prov_isp = map { $_->[0] } @sort_n;

#my $m = stat_prov_isp_cnt('china_ipc.csv');
#my @sort_m = sort { $a->[0] cmp $b->[0] or $a->[1] cmp $b->[1] } @$m;

#my $merge = merge(\@sort_m, \@sort_n, 
#by => [0, 1], 
#value => [2], 
#sep=>',', 
#);
#write_table($merge, file => 'prov_isp.csv', sep=>',');

#my $s = read_table('prov_isp.csv', 
#sep=> ',', 
#charset => 'utf8', 
#return_arrayref => 1, 
#conv_sub => sub {
#my ($r) = @_;
#my $x = format_percent($r->[3]/$r->[2]/255, "%.4f");
#print $x, "\n";
#push @$r, $x; 
#return $r;
#}, 
#skip_sub => sub { $_[0][3]==0 ? 1 : 0 }, 
##write_head => [ qw/prov_isp ip_c_cnt recur_cnt recur_percent/ ], 
#write_file =>'prov_isp.stat.csv', 
#);
#return $s;
#}

#sub chart_prov_to_isp_multi_bar {
#my $isp_cast_r = cast($s, 
#names => [ qw/prov isp all cnt rate/ ], 
#id => [ 0 ],
#measure => 1, 
#value => 3, 

#reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
##write_head => 1, 
#default_cell_value => 0,
#measure_names => \@isp_list, 

#cast_file => 'prov_isp_recur_cnt.cast.stat.csv', 
#return_arrayref => 1, 
#);

#my @sort_isp_cast = sort { 
#$b->[1] <=> $a->[1]
#or $b->[2] <=> $a->[2]
#} @$isp_cast_r;

#my ($cast_r, %opt) = read_chart_data_dim3_horizon(\@sort_isp_cast, 
##skip_head=> 1, 
#label => [0], 
#legend => [ 1 .. 4], 
#names => [ 'prov', @isp_list ], 
##sep=> ',', 
##charset => 'utf8', 
#);

#chart_multi_bar($cast_r, %opt,
#'title' => "运营商 在 各省份 的开放递归个数",
#'file' => "prov_isp_recur_cnt.png",
##with_data_label => 1,
#with_aggregate_data_label => 1, 
#color => \@color, 
#width => 3600, 
#height => 730, 
#plot_area => [ 75, 70, 3500, 600 ],
#with_legend => 1, 
##is_horizontal => 1, 
#);
#crop_img("prov_isp_recur_cnt.png", 0, -10);

#chart_multi_bar($cast_r, %opt,
#'title' => "运营商 在 各省份 的开放递归个数",
#'file' => "prov_isp_recur_cnt_horizon.png",
##with_data_label => 1,
#with_aggregate_data_label => 1, 
#color => \@color, 
#width => 730, 
#height => 3130, 
#plot_area => [ 75, 70, 600, 3000 ],
#with_legend => 1, 
#is_horizontal => 1, 
#);
#crop_img("prov_isp_recur_cnt_horizon.png", 0, -10);
#}

#sub chart_isp_to_prov_bar {

#for my $i (0 .. $#isp_list ){
#my $isp = $isp_list[$i];
#my $isp_en = $isp_en[$i];

#my @sort_s = sort { $b->[3] <=> $a->[3] } grep { $_->[1] eq $isp } @$s;
##print Dumper(\@sort_s);
#my ($r, %opt) = read_chart_data_dim2(
#\@sort_s, 
##skip_head=> 1, 
#label => [0], 
#data => [3], 
##legend => sub { '个数' }, 
#sep=> ',', 
#charset => 'utf8', 
##label_sort => $label_sort, 
##legend_sort => $label_sort, 
#);
##chart_stacked_bar($r, %opt,
#chart_bar($r, %opt,
#'title' => "$isp 开放递归个数（省份）",
#'file' => "prov_isp_recur_cnt_$isp_en.png",
#with_data_label => 1,
#color => \@color, 
#width => 1300, 
#height => 330, 
#plot_area => [ 75, 70, 1200, 200 ],
#);
#crop_img("prov_isp_recur_cnt_$isp_en.png", 0, -10);

##my @sort_r = sort { $b->[4] <=> $a->[4] } grep { $_->[1] eq $isp } @$s;
#my ($r, %opt) = read_chart_data_dim2(
#\@sort_s, 
##'t.stat.csv', 
##skip_head=> 1, 
#label => [0], 
#data => [4], 
#sep=> ',', 
#charset => 'utf8', 
##label_sort => $label_sort, 
##legend_sort => $label_sort, 
#);
#chart_bar($r, %opt,
#'title' => "$isp 开放递归比例（省份）",
#'file' => "prov_isp_recur_rate_$isp_en.png",
#with_data_label => 1,
#data_label_format => '{value}%', 
#y_label_format => '{value}%',
#color => \@color, 
#width => 1600, 
#height => 330, 
#plot_area => [ 75, 70, 1500, 200 ],
#);
#crop_img("prov_isp_recur_rate_$isp_en.png", 0, -10);
#}
#}

#sub stat_prov_isp_cnt {
#my ($f) = @_;

#my $r = cast("$f", 
#sep => ',', 
##names => [ qw/recur state prov_isp isp/ ], 
##names => [ qw/recur cnt state prov_isp isp/ ], 
#skip_sub => sub { ($_[0][-1]!~/^(电信|联通|移动|铁通)$/ or $_[0][-2] eq '未知') ? 1 : 0 }, 
#id => [ -2, -1 ],
#measure => sub { 'cnt' } , 
#value => sub { 1 }, 

#reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
#default_cell_value => 0,

##write_head => 1, 
#cast_file => "$f.prov_isp_cnt.csv", 
#return_arrayref => 1, 
#charset => 'utf8', 
#);
#return $r;
#}
