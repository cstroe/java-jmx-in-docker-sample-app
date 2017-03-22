package com.github.cstroe.loopapp;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class Main {
    private static final Logger log = LogManager.getLogger(Main.class);

    public static void main(String[] args) throws InterruptedException {
        int counter = 0;
        while(true) {
            if(counter % 10 == 0) {
                log.info("Waiting ... {}", counter);
            }
            counter++;
            Thread.sleep(500);
        }
    }
}
