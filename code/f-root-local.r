data_a <- c(
            100,
            0
            )

data_b <- c(
            6.21,
            93.79
            )

data_m <- matrix(c(data_a,data_b), 2, 2)

png('f-root-local.png')

barplot(
        data_m, 
        angle=c(45,135), 
        density=c(10,10), 

        #main="访问F根命中的镜像",
        names.arg=c('ISP_A','ISP_B'),

        xlim=c(0,3),
        legend.text = c("国内镜像","国外镜像"), 
        args.legend = list(x = 3.2, y = 50)
        ) 

dev.off()
