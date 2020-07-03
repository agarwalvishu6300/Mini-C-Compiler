int main()
{
	int arr[5]; 
    arr[0] = 5; 
    arr[2] = -10; 
    arr[3 / 2] = 2;
    arr[3] = arr[0]; 
  	
  	int i;
    for(i = 0; i < 5; i = i + 1) 
    {
    	printf(arr[i]);
    }
}