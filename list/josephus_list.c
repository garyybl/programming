/*
*Josephus环，实现约瑟夫环，并实现翻转的功能
*/

#include <stdio.h>
#include <stdlib.h>

typedef struct node *link;
struct node {
	int item;
	link next;
};

//Make one node
link NODE(int item, link next)
{
	link t = malloc(sizeof(*t));
	if (t == NULL)
	{
		printf("Malloc Fail/n");
		exit(-1);
	}

	t->item = item;
	t->next = next;

	return t;
}

//reverse the ring list
link reverse_list(link head)
{
	link p = head;
	link q = head->next;
	link r;
	p->next = NULL;

	while (q->next != head)
	{
		r = q->next;
		q->next = p;
		p = q;
		q = r;
	}
	
	// Deal with the tail.
	q->next = p;
	head ->next = q;

	return head;

}

// Show list
void show_list(link head)
{
	link t = head;
	
	do {
		printf("%d/n", t->item);
		t = t->next;
	}while (t != head);
	
}

int main(int argc, char *argv[])
{
	int N = atoi(argv[1]);
	int M = atoi(argv[2]);
	int i;
	link t = NODE(1, NULL);

	//Make a list ring;
	t->next = t;
	for (i=2; i<=N; i++)
	{
		t = t->next=NODE(i,t->next);
	}
	
#if 0
	show_list(t->next); 
	reverse_list(t->next); // Reverse
	show_list(t);
#endif	

	//Clear the M position;
	while (t != t->next)
	{
		for (i=1; i<M; i++)
			t = t->next;
		printf("%d/n", t->next->item);
		// Skip the M position;
		t->next = t->next->next;
	}
	// print the last item.
	printf("%d/n", t->item);

	return 0;
}
