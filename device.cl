
// TODO: Add OpenCL kernel code here.
__constant char Sbox[16][16] =
{
	{ 0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76 },
	{ 0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0 },
	{ 0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15 },
	{ 0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75 },
	{ 0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84 },
	{ 0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF },
	{ 0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8 },
	{ 0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2 },
	{ 0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73 },
	{ 0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB },
	{ 0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79 },
	{ 0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08 },
	{ 0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A },
	{ 0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E },
	{ 0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF },
	{ 0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16 }
};
__constant char Rcon[4][10] =
{
	{ 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36 },
	{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
	{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
	{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }
};

__constant char MixCol[4][4] =
{
	{ 0x02,0x03,0x01,0x01 },
	{ 0x01,0x02,0x03,0x01 },
	{ 0x01,0x01,0x02,0x03 },
	{ 0x03,0x01,0x01,0x02 }
};

struct Block {
	char item[4][4];
};

__kernel void encrypt(
__global struct Block* keys,
__global struct Block* plaintext,
__global struct Block* ciphertext,
const unsigned int num_of_blocks ){ 

int id = get_global_id(0);
if (id < num_of_blocks){ 
		//initial add round key
	//Block * ciphertext = new Block[num_of_blocks];
	//for (int t = 0; t < num_of_blocks; t++) {
		for (int i = 0; i < 4; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				ciphertext[id].item[i][j] = plaintext[id].item[i][j];
				ciphertext[id].item[i][j] ^= keys[0].item[i][j];
				printf(" %02x", ciphertext[id].item[i][j] & 0xff);
			}
			printf("\n");
		}
	//}
	//start of 9 rounds
	int num_of_rounds = 9;
	for (int r = 0; r < num_of_rounds; r++) {
		//for (int t = 0; t < num_of_blocks; t++) { // loop for ciphertext[id]
												  //------------------ SubBytes -----------------------
			for (int i = 0; i < 4; ++i) {
				for (int j = 0; j < 4; ++j) {
					int x = (ciphertext[id].item[i][j] & 0xf0) >> 4;
					int y = (ciphertext[id].item[i][j] & 0xf);
					ciphertext[id].item[i][j] = Sbox[x][y];
				}
			}
			//-------------------------- Shift Rows --------------------------
			char temp;
			// Rotate first row 1 columns to left
			temp = ciphertext[id].item[1][0];
			ciphertext[id].item[1][0] = ciphertext[id].item[1][1];
			ciphertext[id].item[1][1] = ciphertext[id].item[1][2];
			ciphertext[id].item[1][2] = ciphertext[id].item[1][3];
			ciphertext[id].item[1][3] = temp;

			// Rotate second row 2 columns to left
			temp = ciphertext[id].item[2][0];
			ciphertext[id].item[2][0] = ciphertext[id].item[2][2];
			ciphertext[id].item[2][2] = temp;
			temp = ciphertext[id].item[2][1];
			ciphertext[id].item[2][1] = ciphertext[id].item[2][3];
			ciphertext[id].item[2][3] = temp;

			// Rotate third row 3 columns to left
			temp = ciphertext[id].item[3][0];
			ciphertext[id].item[3][0] = ciphertext[id].item[3][3];
			ciphertext[id].item[3][3] = ciphertext[id].item[3][2];
			ciphertext[id].item[3][2] = ciphertext[id].item[3][1];
			ciphertext[id].item[3][1] = temp;

			//------------------- end of shift rows --------------------------

			//------------------- mix columns --------------------------------
			char nn[4][4];
			for (int i = 0; i < 4; ++i)
			{
				for (int j = 0; j < 4; ++j)
				{
					char tt[4];
					for (int k = 0; k < 4; ++k)
					{
						char mix_temp;
						if ((char)0x01 == MixCol[i][k])
						{
							mix_temp = ciphertext[id].item[k][j];
						}
						else if ((char)0x02 == MixCol[i][k])
						{
							mix_temp = ciphertext[id].item[k][j] << 1;
							int msb = ((ciphertext[id].item[k][j] & 0x80) >> 7) & 0x01;
							if (msb == 1)
							{
								mix_temp ^= 0x1b;
							}
						}
						else if ((char)0x03 == MixCol[i][k])
						{
							mix_temp = ciphertext[id].item[k][j] << 1;
							int msb = ((ciphertext[id].item[k][j] & 0x80) >> 7) & 0x01;
							if (msb == 1)
							{
								mix_temp ^= 0x1b;
							}
							mix_temp ^= ciphertext[id].item[k][j];
						}
						tt[k] = mix_temp;
					}
					char tempc = tt[0] ^ tt[1] ^ tt[2] ^ tt[3];
					nn[i][j] = tempc;
				}
			}
			for (int i = 0; i < 4; i++)
			{
				for (int j = 0; j < 4; j++)
				{
					ciphertext[id].item[i][j] = nn[i][j];
				}

			} //------------------ end of mix columns --------------------------

			  //------------------------- add round key --------------------------
			for (size_t i = 0; i < 4; i++)
			{
				for (int j = 0; j < 4; j++)
				{
					ciphertext[id].item[i][j] ^= keys[r + 1].item[i][j];
				}
			}
			//------------------ end of round key ---------------------------
		//}
	} //end of 9 rounds

	  //------------------ SubBytes -----------------------
	//for (int t = 0; t < num_of_blocks; t++) {
		for (int i = 0; i < 4; ++i) {
			for (int j = 0; j < 4; ++j) {
				int x = (ciphertext[id].item[i][j] & 0xf0) >> 4;
				int y = (ciphertext[id].item[i][j] & 0xf);
				ciphertext[id].item[i][j] = Sbox[x][y];
			}
		}

		//-------------------------- Shift Rows --------------------------
		char temp;
		// Rotate first row 1 columns to left
		temp = ciphertext[id].item[1][0];
		ciphertext[id].item[1][0] = ciphertext[id].item[1][1];
		ciphertext[id].item[1][1] = ciphertext[id].item[1][2];
		ciphertext[id].item[1][2] = ciphertext[id].item[1][3];
		ciphertext[id].item[1][3] = temp;

		// Rotate second row 2 columns to left
		temp = ciphertext[id].item[2][0];
		ciphertext[id].item[2][0] = ciphertext[id].item[2][2];
		ciphertext[id].item[2][2] = temp;
		temp = ciphertext[id].item[2][1];
		ciphertext[id].item[2][1] = ciphertext[id].item[2][3];
		ciphertext[id].item[2][3] = temp;

		// Rotate third row 3 columns to left
		temp = ciphertext[id].item[3][0];
		ciphertext[id].item[3][0] = ciphertext[id].item[3][3];
		ciphertext[id].item[3][3] = ciphertext[id].item[3][2];
		ciphertext[id].item[3][2] = ciphertext[id].item[3][1];
		ciphertext[id].item[3][1] = temp;

		//------------------- end of shift rows ----------------------------------
		//------------------- add round key -----------------------------
		for (int i = 0; i < 4; i++)
		{
			for (int j = 0; j < 4; j++)
			{
				ciphertext[id].item[i][j] ^= keys[10].item[i][j];
			}
		}
	//} //end of encription 
	}//end of if
}