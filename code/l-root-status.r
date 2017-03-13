data_a <- c(
            1.66
            )

data_b <- c(
            0.951
            )

data_m <- matrix(c(data_a,data_b), 3, 2)

png('l-root-status.png')

barplot(
        data_m, 
        angle=c(45,90,135), 
        density=c(10,10,10), 

        #main="·ÃÎÊL¸ùÊ±ÑÓ×´Ì¬",
        names.arg=c('ISP_A','ISP_B'),

        xlim=c(0,3),
        legend.text = c("ÓÅ","Á¼","²î"), 
        args.legend = list(x = 3, y = 50)
        ) 

dev.off()
