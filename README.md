# dns_root_scaling
a method for dns root scaling，一种评估DNS根镜像服务的方法

We scaled dns root latency in China at 2014. My origin paper was writed at 2015 with Chinese.

英文标题  An Evaluation Method for DNS Root Service Quality

中文标题  [一种评估DNS根服务质量的方法-原稿](paper/An_Evaluation_Method_for_DNS_Root_Service_Quality_2015060663_manuscript.pdf)

[一种评估DNS根服务质量的方法-出版](paper/An_Evaluation_Method_for_DNS_Root_Service_Quality_201612_publish.pdf)

# English 英文

DNS is an important infrastructure of Internet, root server is the start point of authority domain name resolution. Root servers are globally deployed with anycast technology since 2002, but the quality of root mirror service is quite uneven on different areas because of the complexity of network environment. This paper proposes an evaluating method for DNS root service quality, based on probed data of root service in China. The proposed method can check the availability of local root mirror, measure the difference between different provinces and different ISPs, detect abnormal routing and make a comprehensive evaluation of local root service base on above indicators.

## how to scaling dns root service

There are 4 critical levels to scaling dns root service:
* **rtt_status_level**: low rtt latency, good rtt_status ? 
* **local_mirror_level**: most of local resolvers visiting local root mirror instance ? (how many probe nodes visit the F-root beijing mirror when it query to the F-root anycast ip address)
* **route_warn_level**: compare rtt status between Root-labels-deployed-local-mirror with Root-labels-not deployed-local-mirror ? ( F-root should be better than A-root in China, because there are f-root mirror instances in beijing)
* **rtt_diff_level**: rtt status is almost balanced at different provinces ? (all good, all normal, or all bad)

## check rtt_status

    rtt_status =
    ( rtt < 150 ) ? 'good' :
    ( rtt < 300 ) ? 'normal' :
    'bad';

## source data

Take f-root for example.

* Probe f-root **anycast** address from many probe nodes of different ISPs and different provinces in China

 $ dig hostname.bind @f.root-servers.net chaos txt

extract data:

    time: 2015-03-24 00:00:32
    rtt: 80 ms
    rtt_status: good 
    root_server: f.root-servers.net
    root_ipv4: 192.5.5.241
    root_mirror_id: pek2a.f.root-servers.org
    root_mirror_loc: beijing
    probe_ip: xxx.xxx.xxx.xxx
    probe_country: china
    probe_prov: fujian
    probe_isp: telecom


* Probe f-root mirror instance **unicast** address from many probe nodes of different ISPs and different provinces in China

 $ dig cn. @pek2a.f.root-servers.org 

extract data:

    time: 2015-03-24 00:00:32
    rtt: 80 ms
    rtt_status: good 
    root_server: f.root-servers.net
    root_ipv4: 203.119.85.5
    root_mirror_id: pek2a.f.root-servers.org
    root_mirror_loc: beijing
    probe_ip: xxx.xxx.xxx.xxx
    probe_country: china
    probe_prov: fujian
    probe_isp: telecom

# level

## rtt_status_level

    status_rate(probe, isp, root_label, status) : rate of rtt_status==status
    isp_status_rate(isp, root_label, status) : avg of status_rate in different provinces's probe nodes
    mirror_status_rate(root_label, status) : avg of isp_status_rate in different isps
    main_status_rate(status) : avg of mirror_status_rate in different root_labels
    rtt_status_level = main_status_rate('good')

##  local_mirror_level

**only** calc the root_labels which have deploy local root mirror instances in the area.

    local_rate(probe, isp, root_label) : rate of probe visit local root mirror instance
    isp_local_rate(isp, root_label) : avg of local_rate in different provinces's probe nodes
    mirror_local_rate(root_label):  avg of isp_local_rate in different isps
    main_local_rate(): avg of mirror_local_rate in different root_labels

    local_mirror_level = main_local_rate() 

##  route_warn_level

RY: root_labels has deployed local root mirror instances in the area

RN: root_labels didn't deployed local root mirror instances in the area

    rtt_warn(probe, isp, root_label, RN) : rate of { rtt_avg(RY) >= rtt_avg(RN) }
    isp_rtt_warn(isp, root_label, RN) : avg of rtt_warn in different provinces's probe nodes
    mirror_rtt_warn(root_label, RN) : avg of isp_rtt_warn in different isps
    main_rtt_warn(RY, RN) : avg of mirror_rtt_warn in different root_labels of RY set

    root_warn_level = main_rtt_warn(RY, RN)

## rtt_diff_level
    
    rtt_avg(probe, isp, root_label) : avg of rtt 
    isp_rtt_std(isp, root_label) : std of rtt_avg/100ms in different provinces's probe nodes
    mirror_rtt_std(root_label) : avg of isp_rtt_std in different isps
    main_rtt_std() : avg of mirror_rtt_std in different root_labels

    rtt_diff_level = main_rtt_std()

# Chinese 中文

计算机应用研究 2016 增刊 P285

稿件编号	15060663

中文关键词	域名;根镜像;anycast;DNS

英文关键词	domain; root mirror; anycast; DNS

中文摘要	域名解析系统(Domain Name System,DNS)是互联网最重要的基础服务之一,其中根域名服务器是权威域名解析的起点。自2002年左右,根域名服务器广泛采用anycast镜像技术进行全球分散部署。但由于网络环境的复杂性,各地区访问根镜像的效果差异很大。本文针对中国境内所部署的根镜像服务器进行了全面的监测和分析,提出了一种评估DNS根服务安全稳定的方法。该方法能够有效检查本地根镜像的生效情况、不同省份运营商网内及跨网访问差异、根镜像服务路由异常等相关指标,为DNS根服务器的部署规划和性能评估起到指导作用。
