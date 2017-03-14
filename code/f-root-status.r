
data_a <- c(
            0.32
            )

data_b <- c(
            28.822
            )

data_m <- matrix(c(data_a,data_b), 3, 16)

png('f-root-status.png')

barplot(
        data_m, 
        angle=c(45,90,135), 
        density=c(10,10,10), 

        #main="����F��ʱ��״̬",
        names.arg=c("ISP_A", "ISP_B"), 
        xlim=c(0,3),
        legend.text = c("��","��","��"), 
        args.legend = list(x = 3, y = 50)
        ) 

dev.off()
