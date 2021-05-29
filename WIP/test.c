#include <stdio.h>

typedef struct
{
    unsigned int MyInt;
} MyStruct;

void Test1(MyStruct input)
{
    input.MyInt = 66;
}

void Test2(MyStruct *input)
{
    // printf("Input: %i\n", input);
    // struct MyStruct Local = *input;
    input->MyInt = 42;
}

int main()
{
    MyStruct TestStruct;
    TestStruct.MyInt = 11;

    printf("At initialization: %i\n", TestStruct.MyInt);

    Test1(TestStruct);
    printf("After Test1: %i\n", TestStruct.MyInt);

    Test2(&TestStruct);
    printf("After Test2: %i\n", TestStruct.MyInt);
}