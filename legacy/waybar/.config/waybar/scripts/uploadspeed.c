#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define INTERFACE "wlan1"
#define STATE_FILE "/tmp/tx_prev_" INTERFACE

int main() {
    // Path to the tx_bytes file for the network interface
    char tx_path[256];
    snprintf(tx_path, sizeof(tx_path), "/sys/class/net/%s/statistics/tx_bytes", INTERFACE);
    
    // Read previous TX value from state file
    FILE *state_fp = fopen(STATE_FILE, "r");
    unsigned long long tx_prev = 0;
    
    if (state_fp != NULL) {
        // If state file exists, read the previous value
        fscanf(state_fp, "%llu", &tx_prev);
        fclose(state_fp);
    } else {
        // If state file doesn't exist, read current value as baseline
        FILE *tx_fp = fopen(tx_path, "r");
        if (tx_fp == NULL) {
            perror("Error opening tx_bytes");
            return 1;
        }
        fscanf(tx_fp, "%llu", &tx_prev);
        fclose(tx_fp);
    }
    
    // Read current TX value
    FILE *tx_fp = fopen(tx_path, "r");
    if (tx_fp == NULL) {
        perror("Error opening tx_bytes");
        return 1;
    }
    
    unsigned long long tx_next;
    fscanf(tx_fp, "%llu", &tx_next);
    fclose(tx_fp);
    
    // Write current value to state file for next run
    state_fp = fopen(STATE_FILE, "w");
    if (state_fp == NULL) {
        perror("Error opening state file");
        return 1;
    }
    fprintf(state_fp, "%llu", tx_next);
    fclose(state_fp);
    
    // Calculate speed in MB/s
    // Divide by 1024 twice for MB, divide by 2 for 2-second interval
    double tx_speed = (double)(tx_next - tx_prev) / 1024.0 / 1024.0 / 2.0;
    
    // Print with padding: 2 zeros before decimal, 2 after
    printf("%05.2f\n", tx_speed);
    
    return 0;
}
