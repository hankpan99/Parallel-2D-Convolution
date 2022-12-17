#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>

#define BLOCK_SIZE 16

float *d_img, *d_ans, *d_kernel;

__global__ void con(float *d_img, 
                    float *d_ans, 
                    float *d_kernel,
                    int width, 
                    int height, 
                    int k_size, 
                    int pad) {
    
    int r = blockIdx.y * blockDim.y + threadIdx.y;
    int c = blockIdx.x * blockDim.x + threadIdx.x;
    int padded_img_width = width + 2 * pad;

    if (r >= height || c >= width)
        return;

    float res = 0.0;
    for (int kr = -pad; kr <= pad; kr++) {
        for (int kc = -pad; kc <= pad; kc++) {
            res += d_img[(r + pad + kr) * padded_img_width + (c + pad + kc)] * d_kernel[(kr + pad) * k_size + (kc + pad)];
        }
    }
    d_ans[r * width + c] = res;
}

void mallocKernelAndAns(float *kernel_arr, int width, int height, int k_size) {

    cudaMalloc((void **)&d_ans, width * height * sizeof(float));
    cudaMalloc((void **)&d_kernel, k_size * k_size * sizeof(float));
    cudaMemcpy(d_kernel, kernel_arr, k_size * k_size * sizeof(float), cudaMemcpyHostToDevice);

}

void convolution(float *img_arr, 
                 float *ans_arr,
                 int width, 
                 int height, 
                 int k_size, 
                 int pad) {

    // init cuda arr
    cudaMalloc((void **)&d_img, (width + 2 * pad) * (height + 2 * pad) * sizeof(float));
    cudaMemcpy(d_img, img_arr, (width + 2 * pad) * (height + 2 * pad) * sizeof(float), cudaMemcpyHostToDevice);
    
    dim3 blockSize(BLOCK_SIZE, BLOCK_SIZE);
    dim3 numBlock(width / BLOCK_SIZE + 1, height / BLOCK_SIZE + 1);
    con<<<numBlock, blockSize>>>(d_img, d_ans, d_kernel, width, height, k_size, pad);
    
    cudaMemcpy(ans_arr, d_ans, width * height * sizeof(float), cudaMemcpyDeviceToHost);

    cudaFree(d_img);
}

void freeKernelAndAns() {
    cudaFree(d_kernel);
    cudaFree(d_ans);
}