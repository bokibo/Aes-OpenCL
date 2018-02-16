#include <fstream>
#include <cstdlib>
#include <vector>
#include <iostream>
#include <cstdlib>
#include <stdlib.h>
#include "const.h"
#include <CL/cl.h>

//multiplication for Inverse MixColumns
#define xtime(x)   ((x<<1) ^ (((x>>7) & 1) * 0x1b))
#define Multiply(x,y) (((y & 1) * x) ^ ((y>>1 & 1) * xtime(x)) ^ ((y>>2 & 1) * xtime(xtime(x))) ^ ((y>>3 & 1) * xtime(xtime(xtime(x)))) ^ ((y>>4 & 1) * xtime(xtime(xtime(xtime(x))))))
using namespace std;

long file_length(const char* filename) {
	FILE * f = fopen(filename, "r");
	long length;
	if (f)
	{
		fseek(f, 0, SEEK_END);
		length = ftell(f);
		fclose(f);
		return length;
	}
	else
		return 0;
}

char* readKernelSource(const char* filename)
{
	char* kernelSource;
	long length;
	FILE * f = fopen(filename, "r");
	if (f)
	{
		fseek(f, 0, SEEK_END);
		length = ftell(f);
		fseek(f, 0, SEEK_SET);
		kernelSource = (char*)calloc(length, sizeof(char));
		if (kernelSource)
			fread(kernelSource, 1, length, f);
		fclose(f);
	}
	return kernelSource;
}

Block * key_scheduling() {
	Block *keys = new Block[11];
	//initial key
	char key[4][4] = {
	{ 0x54, 0x73, 0x20, 0x67 },
	{ 0x68, 0x20, 0x4b, 0x20 },
	{ 0x61, 0x6d, 0x75, 0x46 },
	{ 0x74, 0x79, 0x6e, 0x75 } };
	/*
	char key[4][4] = {
		{ 'k', 'l', 'j', 'u' },
		{ 'c', ' ', 'z', 'a' },
		{ ' ', 'a', 'e', 's' },
		{ ' ', '1', '2', '8' } };
	*/
	for (int i = 0; i < 4; i++)
	{
		for (int j = 0; j < 4; j++)
		{
			keys[0].item[i][j] = key[i][j];
		}
	}

	// key scheduling algorithm
	for (int k = 1; k <= 10; k++) {
		Block tempNew;
		Block tempOld = keys[k - 1];
		char temp[4] = { tempOld.item[0][3], tempOld.item[1][3], tempOld.item[2][3], tempOld.item[3][3] }; //last column of first key
																										   //ROTWORD
		char t = temp[0];
		temp[0] = temp[1];
		temp[1] = temp[2];
		temp[2] = temp[3];
		temp[3] = t;

		//SUBBYTES
		//cout << endl << "3." << endl;
		for (int i = 0; i < 4; i++) {
			int x = (temp[i] >> 4) & 0xf;
			int y = temp[i] & 0xf;
			temp[i] = Sbox[x][y];
		}

		char temp2[4] = { tempOld.item[0][0], tempOld.item[1][0], tempOld.item[2][0], tempOld.item[3][0] }; //first column of first key
																											//xor second column and temp and Rcon 1st round
		for (int i = 0; i < 4; i++) {
			temp2[i] = temp[i] ^ tempOld.item[i][0];
			temp2[i] = temp2[i] ^ Rcon[i][k - 1];
		}

		for (int i = 0; i < 4; i++)  //first column of 2nd key
			tempNew.item[i][0] = temp2[i];

		for (int j = 1; j < 4; j++) {
			for (int i = 0; i < 4; i++)
			{
				tempNew.item[i][j] = (tempNew.item[i][j - 1] ^ tempOld.item[i][j]);
			}
		}
		keys[k] = tempNew;
	} //end of key scheduling
	return keys;
}

Block* plaintext_initialization(int num_of_blocks) {

	Block * temp_plaintext = new Block[num_of_blocks];
	Block * plaintext = new Block[num_of_blocks];
	ifstream ifs("text.txt");
	int k = 0;
	while (ifs) {
		ifs.read((char*)temp_plaintext[k].item, 16);
		k++;
	}

	for (int t = 0; t < num_of_blocks; t++) {
		for (int i = 0; i < 4; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				//cout << " " <<plaintext[t].item[i][j];
				//cout << " " << hex << (int)(plaintext[t].item[i][j] & 0xff);
				plaintext[t].item[j][i] = temp_plaintext[t].item[i][j];
			}
		}
	}
	//cout << "----- Plaintext ------" << endl;
	for (int t = 0; t < num_of_blocks; t++) {
		for (int i = 0; i < 4; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				//cout << " " << plaintext[t].item[i][j];
				//cout << " " << hex << (int)(plaintext[t].item[i][j] & 0xff);
			}
			//cout << endl;
		}
		//cout << "-----------------------" << endl;
	}
	return plaintext;
}

int main(int argc, char* argv[]) {

	long plaintext_length = file_length("text.txt");
	int num_of_blocks = plaintext_length / 16 + 1;
	Block *keys = key_scheduling();

	/*for (size_t ii = 0; ii < 11; ii++)
	{
		for (size_t jj = 0; jj < 4; jj++) {
			for (size_t kk = 0; kk < 4; kk++)
			{
				cout << " " << hex << (int)(keys[ii].item[jj][kk] & 0xff);
			}
			cout << endl;
		}
		cout << "--------------" << endl;
	}*/

	Block *plaintext = plaintext_initialization(num_of_blocks);
	Block *ciphertext = new Block[num_of_blocks];
	cl_mem buff;					//memory buffer
	cl_platform_id cpPlatform;		//CL platform
	cl_device_id device_id;			//device ID
	cl_context context;				//context
	cl_command_queue queue;			//queue
	cl_program program;				//program, cpp file
	cl_kernel kernel;				//kernel, CL file

	cl_mem ciphertext_d;
	cl_mem plaintext_d;
	cl_mem keys_d;

	size_t globalSize, localSize;
	cl_int err;

	localSize = 64; //how to calcute this for optimal performance
	globalSize = (size_t)ceil(num_of_blocks / (float)localSize)*localSize; 

																		   
	err = clGetPlatformIDs(1, &cpPlatform, NULL);

	//device ID 
	err = clGetDeviceIDs(cpPlatform, CL_DEVICE_TYPE_GPU, 1, &device_id, NULL);

	//context
	context = clCreateContext(0, 1, &device_id, NULL, NULL, &err);

	//command queue
	queue = clCreateCommandQueue(context, device_id, 0, &err);

	//kernel file
	char* kernelSource = readKernelSource("device.cl");

	//program
	program = clCreateProgramWithSource(context, 1, (const char**)&kernelSource, NULL, &err);

	//build
	err = clBuildProgram(program, 0, NULL, NULL, NULL, NULL);

	if (err)
	{
		
		size_t log_size;
		clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, 0, NULL, &log_size);
		// Allocate memory for the log
		char *log = (char *)malloc(log_size);
		// Get the log
		clGetProgramBuildInfo(program, device_id, CL_PROGRAM_BUILD_LOG, log_size, log, NULL);
		// Print the log
		printf("%s\n", log);
		free(log);
	}

	//running kernel
	kernel = clCreateKernel(program, "encrypt", &err);

	keys_d = clCreateBuffer(context, CL_MEM_READ_ONLY, 11 * sizeof(Block), NULL, NULL);
	plaintext_d= clCreateBuffer(context, CL_MEM_READ_ONLY, num_of_blocks * sizeof(Block), NULL, NULL);
	ciphertext_d = clCreateBuffer(context, CL_MEM_WRITE_ONLY, num_of_blocks * sizeof(Block), NULL, NULL);

	err = clEnqueueWriteBuffer(queue, keys_d, CL_TRUE, 0, 11 * sizeof(Block), keys, 0, NULL, NULL);
	err = clEnqueueWriteBuffer(queue, plaintext_d, CL_TRUE, 0, num_of_blocks * sizeof(Block), keys, 0, NULL, NULL);

	//setting arguments
	err = clSetKernelArg(kernel, 0, sizeof(cl_mem), &keys_d);
	err = clSetKernelArg(kernel, 1, sizeof(cl_mem), &plaintext_d);
	err = clSetKernelArg(kernel, 2, sizeof(cl_mem), &ciphertext_d);
	err = clSetKernelArg(kernel, 3, sizeof(int), &num_of_blocks);

	err = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &globalSize, &localSize, 0, NULL, NULL);
	clFinish(queue);

	clEnqueueReadBuffer(queue, ciphertext_d, CL_TRUE, 0, num_of_blocks*sizeof(Block), ciphertext, 0, NULL, NULL);
	/*
	cout << "----- ciphertext -----" << endl;
	for (int t = 0; t < num_of_blocks; t++) {
		for (int i = 0; i < 4; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				cout << " " << hex << (int)(ciphertext[t].item[i][j] & 0xff);
			}
			cout << endl;
		}
		cout << "--------------" << endl;
	}
	*/
	clReleaseMemObject(keys_d);
	clReleaseMemObject(plaintext_d);
	clReleaseMemObject(ciphertext_d);
	clReleaseProgram(program);
	clReleaseKernel(kernel);
	clReleaseCommandQueue(queue);
	clReleaseContext(context);

	free(keys);
	free(plaintext);
	free(ciphertext);
	free(kernelSource);

	// -------------------------------  encription  -----------------------------------

	

	
	//cout << "----- Plaintext ------" << endl;

	
	system("pause");
}