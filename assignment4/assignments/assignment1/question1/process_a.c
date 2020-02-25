#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdio.h>
#include <stdlib.h> /* for exit */
#include <string.h>


/*
 * shm-server - not sure of the origin of code segment.
 * Old source, not sure of the origin
 *  possibly: David Marshalls course : http://www.cs.cf.ac.uk/Dave/C/CE.html
 * or Steve Holmes : http://www2.its.strath.ac.uk/courses/c/
 */



#define SHMSZ     27


int
main()
{

    int shmid, shmid2;
    key_t key, key2;
    char *shm,*s, *sharedmem2, *shared2;

    key = 0511;
    key2 = 0622;
    /*
     * Create the segment.
     */
    if( (shmid = shmget(key, SHMSZ, IPC_CREAT | 0666)) < 0 )
    {
        perror("shmget");
        exit(1);
    }

    //Create second segment
        if( (shmid2 = shmget(key2, SHMSZ, IPC_CREAT | 0666)) < 0 )
    {
        perror("shmget");
        exit(1);
    }

    /*
     * Now we attach the segment to our data space.
     */
    if( (shm = shmat(shmid, NULL, 0)) == (char *) -1 )
    {
        perror("shmat");
        exit(1);
    }

        /*
     * Now we attach the second segment to our data space.
     */
    if( (sharedmem2 = shmat(shmid2, NULL, 0)) == (char *) -1 )
    {
        perror("shmat");
        exit(1);
    }

    s = shm;
    *s = '1';


    while( *shm != '3' )
        sleep(1);
    
    printf("\nGoodBye");


    shmdt(s);
    shmdt(shared2);
    shmctl(shmid, IPC_RMID, NULL);
    shmctl(shmid2, IPC_RMID,NULL);


    return 0;
}
