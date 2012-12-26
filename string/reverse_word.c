/*
*将一个字符串以单词为单位进行逆序输出。
*/

#include <stdio.h>
#include <string.h>

void reverse_string(char *str, int start, int end)
{
	char tmp;
	int i;
	
	for ( ; start<end; start++, end--)
	{
		tmp = str[start];
		str[start] = str[end];
		str[end] = tmp;
	}

	return;
}

void reverse_word(char *str)
{
	int i, j, n;

	// reverse the whole string.
	reverse_string(str, 0, strlen(str)-1);

	// revesese every word.
	for (i=j=n=0; str[n]; n++)
	{
		if (str[n] == ' ')
			j=n;
		else
			if (str[i] == ' ')
				i=n;
				
		// find a word and reverse it.
		if (i<j && (str[j-1]!=' ') && (str[i]!= ' '))
		{
			reverse_string(str, i, j-1);
		//	printf("%s/n", str);
			i=j;   //move to next word.		
		}
	}

    // Reverse last word.
	if ((str[strlen(str)-1] != ' ') && (str[i]!= ' '))
	{
		reverse_string(str, i, strlen(str)-1);
	}
	
}

int main(void)
{
	char str[]= "Make it right before you make it faster";
	
	printf("Orginal string:[%s]\n", str);
	//reverse_string(str, 0, strlen(str)-1);
	reverse_word(str);
	
	printf("Reverse string:[%s]\n", str);
	return 0;
}
