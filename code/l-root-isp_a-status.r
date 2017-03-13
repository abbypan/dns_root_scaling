data <- c(
c(0.992992993,0.001001001,0.006006006),
c(0.312693498,0.646026832,0.04127967)
          )

data_m <- matrix(data, 3, 23)

png('l-root-isp_a-status.png', width=1200)

barplot(
        data_m, 
        #width=c(1.5,1.5,1.5),
        angle=c(45,90,135), 
        density=c(10,10,10), 

        #main="访问F根时延状态",
        names.arg=c("江苏","河南","四川","陕西","西藏","广东","重庆","云南","海南","贵州","湖南","上海","湖北","广西","江西","浙江","甘肃","青海","新疆","宁夏","安徽","福建","山东"),
        width=1.6,
        #space=1,
        xlim=c(0,45),
        legend.text = c("优","良","差"), 
        args.legend = list(x = 46.5, y = 0.5) 
        ) 

dev.off()
