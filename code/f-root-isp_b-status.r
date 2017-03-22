data <- c(
          c(0,0.384538153,0.615461847)
          )

data_m <- matrix(data, 3, 16)

png('f-root-isp_b-status.png', width=900)

barplot(
        data_m, 
        #width=c(1.5,1.5,1.5),
        angle=c(45,90,135), 
        density=c(10,10,10), 

        #main="·ÃÎÊF¸ùÊ±ÑÓ×´Ì¬",
        names.arg=c("Ìì½ò"),
        width=3,
        #space=1,
        xlim=c(0,60),
        legend.text = c("ÓÅ","Á¼","²î"), 
        args.legend = list(x = 62, y = 0.5) 
        ) 

dev.off()
