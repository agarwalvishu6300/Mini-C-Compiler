int x;

void addition(int y) {
	x = x + y;
}

void subtraction(int y) {
	x = x - y;
}

void multiplication(int y) {
	x = x * y;
}

void division(int y) {
	x = x / y;
}

int main() {
	x = 0;

	addition(7);
	subtraction(2);

	addition(14);
	subtraction(7);

	multiplication(5);
	division(6);
	
	printf(x);
}