data <- c(
c(0.312693498,0.646026832,0.04127967)
          )

data_m <- matrix(data, 3, 23)

png('l-root-isp_a-status.png', width=1200)

barplot(
        data_m, 
        #width=c(1.5,1.5,1.5),
        angle=c(45,90,135), 
        density=c(10,10,10), 

        #main="·ÃÎÊF¸ùÊ±ÑÓ×´Ì¬",
        names.arg=c("½­ËÕ"),
        width=1.6,
        #space=1,
        xlim=c(0,45),
        legend.text = c("ÓÅ","Á¼","²î"), 
        args.legend = list(x = 46.5, y = 0.5) 
        ) 

dev.off()
