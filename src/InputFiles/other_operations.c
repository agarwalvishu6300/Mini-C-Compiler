int divby2 (int n)
{
	int x;
	x = n%2;
	if(x == 0) {
		return 1;
	}
	else {
		return 0;
	}
}

int divby3 (int n)
{
	int x;
	x = n%3;
	if(x == 0) {
		return 1;
	}
	else {
		return 0;
	}
}

int divby6 (int n)
{
	int x;
	x = n%6;
	if(x == 0) {
		return 1;
	}
	else {
		return 0;
	}
}

int main()
{
	int i;
	for(i = 1; i < 20; i = i + 1)
	{
		if( ( divby2 (i) || divby3 (i) ) && ( ! divby6 (i) ) )
		{
			printf(i);
		}
	}
}
