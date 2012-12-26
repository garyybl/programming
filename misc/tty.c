/*
* 	Simply use to test at channel, send at command and return ok.
*/
#include     <stdio.h>
#include     <stdlib.h> 
#include     <unistd.h>  
#include     <sys/types.h>
#include     <sys/stat.h>
#include     <fcntl.h> 
#include     <termios.h>
#include     <errno.h>
#include 	<string.h>

#define TTY_DEV_PATH "/dev/ttyS3"

/* for input buffering */
#define MAX_AT_RESPONSE 1024

static char s_ATBuffer[MAX_AT_RESPONSE+1];
static char *s_ATBufferCur = s_ATBuffer;

void  AT_DUMP(const char*  prefix, const char*  buff, int  len)
{
    if (len < 0)
        len = strlen(buff);
    printf("%.*s", len, buff);
}

static char * findNextEOL(char *cur)
{
    if (cur[0] == '>' && cur[1] == ' ' && cur[2] == '\0') {
        /* SMS prompt character...not \r terminated */
        return cur+2;
    }

    // Find next newline
    while (*cur != '\0' && *cur != '\r' && *cur != '\n') cur++;

    return *cur == '\0' ? NULL : cur;
}


static const char *readline(int fd){
    ssize_t count;

    char *p_read = NULL;
    char *p_eol = NULL;
    char *ret;
    int s_fd = fd;

    if (*s_ATBufferCur == '\0') {
        /* empty buffer */
        s_ATBufferCur = s_ATBuffer;
        *s_ATBufferCur = '\0';
        p_read = s_ATBuffer;
    } else {   /* *s_ATBufferCur != '\0' */
        /* there's data in the buffer from the last read */

        // skip over leading newlines
        while (*s_ATBufferCur == '\r' || *s_ATBufferCur == '\n')
            s_ATBufferCur++;

        p_eol = findNextEOL(s_ATBufferCur);

        if (p_eol == NULL) {
            /* a partial line. move it up and prepare to read more */
            size_t len;

            len = strlen(s_ATBufferCur);

            memmove(s_ATBuffer, s_ATBufferCur, len + 1);
            p_read = s_ATBuffer + len;
            s_ATBufferCur = s_ATBuffer;
        }
        /* Otherwise, (p_eol !- NULL) there is a complete line  */
        /* that will be returned the while () loop below        */
    }

    while (p_eol == NULL) {
        if (0 == MAX_AT_RESPONSE - (p_read - s_ATBuffer)) {
            printf("ERROR: Input line exceeded buffer\n");
            /* ditch buffer and start over again */
            s_ATBufferCur = s_ATBuffer;
            *s_ATBufferCur = '\0';
            p_read = s_ATBuffer;
        }

        do {
            count = read(s_fd, p_read,
                            MAX_AT_RESPONSE - (p_read - s_ATBuffer));
        } while (count < 0 && errno == EINTR);


        if (count > 0) {
            AT_DUMP( "<< ", p_read, count );
            //s_readCount += count;

            p_read[count] = '\0';

            // skip over leading newlines
            while (*s_ATBufferCur == '\r' || *s_ATBufferCur == '\n')
                s_ATBufferCur++;

            p_eol = findNextEOL(s_ATBufferCur);
            p_read += count;
        } else if (count <= 0) {
            /* read error encountered or EOF reached */
            if(count == 0) {
                printf("atchannel: EOF reached");
            } else {
                printf("atchannel: read error %s", strerror(errno));
            }
            return NULL;
        }
    }

    /* a full line in the buffer. Place a \0 over the \r and return */

    ret = s_ATBufferCur;
    *p_eol = '\0';
    s_ATBufferCur = p_eol + 1; /* this will always be <= p_read,    */
                              /* and there will be a \0 at *p_read */

    printf("AT< %s\n", ret);
    return ret;
}


int main(void)
{
    int fd;
    int i;
    int len;
    int n = 0;      
    char read_buf[256];
    char write_buf[256];
    struct termios opt; 
    unsigned long count = 0;

char *read_value = NULL;

    fd = open(TTY_DEV_PATH, O_RDWR| O_NOCTTY);    //默认为阻塞读方式
    if(fd == -1)
    {
        perror("open serial 0\n");
        exit(0);
    }
	fcntl(fd, F_SETFL, 0);
	#if 1
    tcgetattr(fd, &opt);      
    cfsetispeed(&opt, B115200);
    cfsetospeed(&opt, B115200);
    
    if(tcsetattr(fd, TCSANOW, &opt) != 0 )
    {     
       perror("tcsetattr error");
       return -1;
    }
    
    opt.c_cflag &= ~CSIZE;  
    opt.c_cflag |= CS8;   
    opt.c_cflag &= ~CSTOPB; 
    opt.c_cflag &= ~PARENB; 
  //  opt.c_cflag &= ~INPCK;
    opt.c_cflag |= (CLOCAL | CREAD);
 
    opt.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
 
    opt.c_oflag &= ~OPOST;

    //opt.c_oflag &= ~(ONLCR | OCRNL);    //添加的
 
    //opt.c_iflag &= ~(ICRNL | INLCR);
   // opt.c_iflag &= ~(IXON | IXOFF | IXANY);    //添加的
    opt.c_cflag |= CRTSCTS;   //hardware flow control.
    opt.c_cc[VTIME] = 0;
    opt.c_cc[VMIN] = 0;
    
    tcflush(fd, TCIOFLUSH);
 
    printf("%s:configure complete\n",TTY_DEV_PATH);
    
    if(tcsetattr(fd, TCSANOW, &opt) != 0)
    {
        perror("serial error");
        return -1;
    }
	#endif
    printf("start send and receive data\n");


    while(1)
    {    
        n = 0;
        len = 0;
	count++;
        bzero(read_buf, sizeof(read_buf));    //类似于memset
        bzero(write_buf, sizeof(write_buf));
	strcpy(write_buf, "AT\r\n");
        
        n = write(fd, "AT\r\n", 3);
		if (n < 0)
		{
			printf("==[%d]===Write ERROR\n",count);
		//	return -1;
		//	break;
		}
		else
		{
			printf("==[%d]==Write Success\n", count);
		}
read_again:
//-----------------------------------------------------
	read_value = readline(fd);  //仿照RIL 代码的read方式
	printf("====Read Success: read buf :%s \n",read_value);
//---------------------------------------------------
/*
		n = read(fd, read_buf, sizeof(read_buf));
		if (n > 0)
		{
			printf("==[%d]==Read Success: read buf : [%s],read size:[%d]\n", count, read_buf, n);
			printf("Recevie buf:");
			for (i=0; i<n; i++)
			{
				printf("[%d]", read_buf[i]); 
			}
			printf("\n");
			if ( !( ((read_buf[0]=='O')&&(read_buf[1]=='K')) || ((read_buf[0]=='E')&&(read_buf[1]=='R')) ) )
				goto read_again;	
		}
		else
		{
			printf("==[%d]==Read ERROR:%d\n", count,n);
		//	return -1;
		//	break;
		}
*/
//        while( (n = read(fd, read_buf, sizeof(read_buf))) > 0 )
//        {
//            for(i = len; i < (len + n); i++)
//            {
//                write_buf[i] = read_buf[i - len];
//            }
//            len += n;
//        }
//        write_buf[len] = '\0';
              
//        printf("Len %d \n", len);
//        printf("%s \n", write_buf);
 
//        n = write(fd, write_buf, len);
//        printf("write %d chars\n",n);

        sleep(2);
    }
	close(fd);
}
