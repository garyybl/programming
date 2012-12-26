/*
*1.String:将所有的空格移到字符串的末尾
*2.删除字符串中的所有空格，并返回该字符串
*/
#include <stdio.h>  
#include <string.h>  
  
  
//删除字符串中的所有空格，并返回该字符串。  
char *del_space(char *s)  
{  
    char *p, *q;  
  
    for (p=q=s; *p; p++)  
    {  
        if (*p != ' ')  
        {  
            if (p != q)  
                *q = *p;  
            q++;  
        }  
    }
    *q = '\0';  
    return s;  
}  
  
//将所有的空格移到字符串的末尾  
char *move_space(char *s)  
{  
    char *p, *q;  
  
    for (p=q=s; *p; p++)  
    {  
        if (*p != ' ')  
        {  
            if (p != q)  
            {  
                *q = *p;  
                *p = ' ';  
            }
            q++;  
        }  
    }  
  
    return s;  
  
}  
  
// Test main  
int main(void)  
{  
    char buf[1024];  
    char *p;  
    gets(buf);  
  	printf("orginal string:[%s]\n", buf);
    del_space(buf);  
    //move_space(buf);  
      
    printf("space string:[%s]\n", buf);  
  
    return 0;  
}  
