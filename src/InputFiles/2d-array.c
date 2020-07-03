int main()
{
	int x[3][5];
	int i,j;

	for(i=0; i<3; i=i+1)
	{
		for(j=0; j<5; j=j+1)
		{
			x[i][j] = i*j;
			printf(x[i][j]);
		}
	}

	int ans;
	ans = 0;
	for(i=0; i<3; i=i+1)
	{
		for(j=0; j<5; j=j+1)
		{
			ans = ans + x[i][j];
		}
	}
	printf(ans);
}