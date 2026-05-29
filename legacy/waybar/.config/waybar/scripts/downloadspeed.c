#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INTERFACE "wlan1"
#define STATE_FILE "/tmp/rx_prev_" INTERFACE

int main() {
    // Path to the rx_bytes file for the network interface
    char rx_path[256];
    snprintf(rx_path, sizeof(rx_path), "/sys/class/net/%s/statistics/rx_bytes", INTERFACE);
    
    // Read previous RX value from state file
    FILE *state_fp = fopen(STATE_FILE, "r");
    unsigned long long rx_prev = 0;
    
    if (state_fp != NULL) {
        // If state file exists, read the previous value
        fscanf(state_fp, "%llu", &rx_prev);
        fclose(state_fp);
    } else {
        // If state file doesn't exist, read current value as baseline
        FILE *rx_fp = fopen(rx_path, "r");
        if (rx_fp == NULL) {
            perror("Error opening rx_bytes");
            return 1;
        }
        fscanf(rx_fp, "%llu", &rx_prev);
        fclose(rx_fp);
    }
    
    // Read current RX value
    FILE *rx_fp = fopen(rx_path, "r");
    if (rx_fp == NULL) {
        perror("Error opening rx_bytes");
        return 1;
    }
    
    unsigned long long rx_next;
    fscanf(rx_fp, "%llu", &rx_next);
    fclose(rx_fp);
    
    // Write current value to state file for next run
    state_fp = fopen(STATE_FILE, "w");
    if (state_fp == NULL) {
        perror("Error opening state file");
        return 1;
    }
    fprintf(state_fp, "%llu", rx_next);
    fclose(state_fp);
    
    // Calculate speed in MB/s
    // Divide by 1024 twice for MB, divide by 2 for 2-second interval
    double rx_speed = (double)(rx_next - rx_prev) / 1024.0 / 1024.0 / 2.0;
    
    // Print with padding: 2 zeros before decimal, 2 after
    printf("%05.2f\n", rx_speed);
    
    return 0;
}
