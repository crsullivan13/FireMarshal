#include <stdio.h>

#define SIZE 8000

int arr[SIZE];
int count = 0;

int main(int argc, char** argv)
{
  printf("Hello World %d\n", argc);

  while ( count != 1000000 ) {
    arr[count % SIZE] = 25;
    count += 1;
  }

  printf("Done\n");

	return 0;
}


