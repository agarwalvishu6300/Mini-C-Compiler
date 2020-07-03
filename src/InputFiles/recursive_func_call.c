int factorial (int n)
{
	if(n <= 1) {
		return 1;
	}

	return n * factorial(n-1);
}

int main()
{
	int x;
	x = 6;

	int ans;
	ans = factorial(x);
	printf(ans);
}
