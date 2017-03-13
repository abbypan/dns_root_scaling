data_a <- c(
            100,
            0
            )

data_b <- c(
            100,
            0
            )

data_m <- matrix(c(data_a,data_b), 2, 2)

png('l-root-local.png')

barplot(
        data_m, 
        angle=c(45,135), 
        density=c(10,10), 

        #main="����L�����еľ���",
        names.arg=c('ISP_A','ISP_B'),

        xlim=c(0,3),
        legend.text = c("���ھ���","���⾵��"), 
        args.legend = list(x = 3.2, y = 50)
        ) 

dev.off()