data <- c(
          c(0.941297631,0.032955716,0.025746653),
          c(0,0.384538153,0.615461847)
          )

data_m <- matrix(data, 3, 16)

png('f-root-isp_b-status.png', width=900)

barplot(
        data_m, 
        #width=c(1.5,1.5,1.5),
        angle=c(45,90,135), 
        density=c(10,10,10), 

        #main="访问F根时延状态",
        names.arg=c("天津","河南","安徽","河北",
                    "内蒙古","上海","陕西","辽宁",
                    "广东","四川","湖南","吉林",
                    "黑龙江","山西","山东","湖北"),
        width=3,
        #space=1,
        xlim=c(0,60),
        legend.text = c("优","良","差"), 
        args.legend = list(x = 62, y = 0.5) 
        ) 

dev.off()
