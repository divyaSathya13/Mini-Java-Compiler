%{
	#include <stdlib.h>
	#include <string.h>
	#include <stdio.h>
	#define YYSTYPE char*
	FILE *yyin;
	int yylex();
	char* type;
	int err = 0;
	FILE* fp;
	typedef struct NODE
	{
	char name[10];
	int value;
	char type[10];
	int scope;
	int lineno;
	int size;
	struct NODE* next;
	}NODE;

	typedef struct symbol_table
	{
		NODE* head;
		int entries;
	}TABLE;
	TABLE* s;
	int scope = 0;
	void yyerror(char* s);
	void print();
	int exists(char* name);
	void scopered(int scope);
	void update(char* name, int val,int lineno);
	void insert(char* name, int value, char* type,int lineno) ;
	char* calculate(char* opr,int op1,int op2);
	extern int yylineno;
%}
%token T_IMPORT T_CLASS T_PUBLIC T_PRIVATE T_PROTECTED T_STATIC T_FINAL T_VOID T_INT T_CHAR T_DOUBLE T_IF T_ELSE T_SWITCH T_CASE T_DEFAULT T_BREAK T_CONTINUE T_RETURN T_NEW T_INC T_DEC T_SHA T_SHS T_SHM T_SHD T_SHAND T_SHO T_SHC T_SHMOD T_OR T_AND T_EQ T_NE T_GTE T_LTE T_LS T_RS T_NUM T_ID T_STRING T_ARGS T_PRINT

%%
Start:Import_S Start|Class_declaration;
Import_S:T_IMPORT T_ID'.'T_ID'.''*'';';
Class_declaration:Modifier T_CLASS T_ID '{'Class_body'}';
Class_body:Global_variable_declaration Class_body|Method_declaration Class_body|;
Global_variable_declaration:Modifier Variable_declaration;
Method_declaration:Modifier Type T_ID'('Parameters')'Block|Modifier T_VOID T_ID'('Parameters')'Block;
Modifier:T_PUBLIC Modifier1|T_PRIVATE Modifier1|T_PROTECTED Modifier1|Modifier1;
Modifier1:T_STATIC Modifier2|Modifier2;
Modifier2:T_FINAL|;
Parameters:List_of_parameters;
List_of_parameters:Type T_ID|Type T_ID',' Parameters|Type'['']' T_ARGS;
Block:'{'{scope+=1;}S'}'{scope-=1;};
S:Assignment S|T_BREAK';' S|T_CONTINUE';' S|T_IF'('Expression')'S|T_IF '('Expression')' Block S|T_IF'('Expression')'Block T_ELSE Block |T_RETURN Expression';' S|T_SWITCH'('Expression')' '{' {scope+=1;}SwitchBlock'}'{scope-=1;} S|Variable_declaration S|Array_declaration';' S|Array_initialisation';' S| T_PRINT'('Expression')' ';' S|
H';'|error ';' S|;
H:T_ID T_INC|T_ID T_DEC|T_INC T_ID|T_DEC T_ID;
SwitchBlock:SwitchLabel S SwitchBlock|;
SwitchLabel:T_CASE Expression|T_DEFAULT;
Variable_declaration:Type T_ID '=' Expression{insert($2, atoi($4), $1,yylineno);	} Identifier_list';'|Type T_ID{insert($2, 0, $1,yylineno);} Identifier_list';';
Identifier_list:','T_ID '=' Expression Identifier_list{insert($2, atoi($4), type,yylineno);}|','T_ID Identifier_list{insert($2, 0, type,yylineno);}|;
Array_declaration:Type B T_ID|Type T_ID B;
B:'['']'B|'['']';
BB:'[' BNUM ']' | '[' BNUM ']' BB; 
BNUM : T_NUM | T_ID;
Array_initialisation:Array_declaration Assignment_operator K;
K:V|V','K|T_NEW Type BB;
V:T_NUM|R;
R:'{'K'}';
Type:T_INT|T_DOUBLE|T_CHAR|T_STRING;
Assignment:T_ID Assignment_operator Expression';'{
		//printf("declaration: $$=%s $1=%s $2=%s $3=%s\n",$$, $1, $2, $3);
		if(exists($1)){
			update($1,atoi($3),yylineno);
		}
		else
		{
			printf("Variable %s not declared at line %d\n",$1,yylineno);
		}
	};
Assignment_operator:'='|T_SHA|T_SHS|T_SHM|T_SHD|T_SHAND|T_SHO|T_SHC|T_SHMOD|';';
Operators:T_OR|T_AND|'|'|'^'|'&'|T_EQ|T_NE|'<'|'>'|T_LTE|T_GTE|T_LS|T_RS|'+'|'-'|'*'|'/'|'%';
Expression:Expr|Expr Operators Expression{$$=calculate($2, atoi($1),atoi($3));};
Expr:'('Expression')'|T_NUM|T_ID{if(exists($1)){
	NODE* temp = s->head;
	while(temp != NULL)
	{
		if(strcmp(temp->name,$1) == 0 && temp->scope <= scope)
			sprintf($$,"%d\n",temp->value);
		temp = temp->next;
	}
	}
	else
	{
		printf("Variable %s not declared at line %d\n",$1,yylineno);
	}};


%%
void yyerror(char *s)
{
	printf("Panic mode recovery at line : %d  \n",yylineno);
	yynerrs+=1;
}
int main(int argc, char* argv[])
{
	s = (TABLE *)malloc(sizeof(TABLE));
	s->head=NULL;
	s->entries=0;
	fp = fopen("symbol_table.txt","w");
	yyin = fopen(argv[1], "r");
	if(!yyparse())
	{
		printf("Succesful parsing\n");
		print();
		return 0;
	}
	else
	{
		printf("Unsuccessful\n");
	}
	return 0;
}
void insert(char* name, int value, char* type,int lineno)
{
	if(exists(name))
	{
		printf("Variable %s already declared\n",name);
		err++;
		return;
	}
    	NODE* test = (NODE*) malloc(sizeof(NODE));
    	strcpy(test->name,name);
	test->value=value;
	test->next=NULL ;
	test->lineno=lineno;
	test->scope=scope;
	if(strcmp(type,"int")==0)
	{
		test->size=4;
	}
	if(strcmp(type,"char")==0)
	{
		test->size=2;
	}
	if(strcmp(type,"float")==0)
	{
		test->size=4;
	}
	if(strcmp(type,"long")==0)
	{
		test->size=8;
	}
	if(strcmp(type,"double")==0)
	{
		test->size=8;
	}
	strcpy(test->type, type);

	NODE* h = s->head;

	if(h==NULL)
	{

		s->head=test;
		s->entries+=1;
		print();
		return;
	}
	while(h->next!=NULL)
	{
		h=h->next;
	}
	h->next=test;
	s->entries+=1;
	//print();
}

int exists(char* name)
{
	NODE* temp = s->head;
	if(s->head == NULL)
		return 0;
	while(temp != NULL)
	{
		if(strcmp(temp->name,name) == 0 && temp->scope <= scope)
			return 1;
		temp = temp->next;
	}
	return 0;
}

void update(char* name, int val,int lineno)
{
	NODE* temp = s->head;
	while(temp!=NULL)
	{
	//printf("%s\n",temp->name);
		if(strcmp(temp->name,name) == 0){
		//printf("%d\n",temp->value);
			temp->value = val;
			temp->lineno=lineno;
		}
		temp = temp->next;
	}
	//print();
}

void print()
{
	NODE* h = s->head;
	fp = fopen("symbol_table.txt","w");
	fprintf(fp,"\nSymbol table\n");

        fprintf(fp, "Name        Value        Type        Scope        lineno        size\n");
	for(int i=0;i<s->entries; i++ )
	{
		fprintf(fp,"%2s %12d %11s %11d %12d %11d\n", h->name, h->value, h->type, h->scope,h->lineno,h->size);
		h=h->next;
	}
}
char* calculate(char* opr,int op1,int op2)
{
	char* result;
	result = (char*)malloc(sizeof(char)*30);
	int oper1 = op1;
	int oper2 = op2;
	int res;
	if(strcmp(opr,"+")==0)
	{
		res = oper1 + oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"-")==0)
	{
		res = oper1 - oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}	
	else if(strcmp(opr,"*")==0)
	{
		res = oper1 * oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}	
	else if(strcmp(opr,"/")==0)
	{
		if(oper2==0)
		{
			printf("division by zero\n");
			exit(0);
		}
		else
		{

			res = oper1 / oper2;
			printf("%d %d %d\n",oper1,oper2,res);
		}
	}
	else if(strcmp(opr,">")==0)
	{
		res = oper1 > oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"<")==0)
	{
		res = oper1 < oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,">=")==0)
	{
		res = oper1 >= oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"<=")==0)
	{
		res = oper1 <= oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"%")==0)
	{
		res = oper1 % oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"==")==0)
	{
		res = oper1 == oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"!=")==0)
	{
		res = oper1 != oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"&&")==0)
	{
		res = oper1 && oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	else if(strcmp(opr,"||")==0)
	{
		res = oper1 || oper2;
		//printf("%d %d %d\n",oper1,oper2,res);
	}
	sprintf(result, "%d", res);
	return result;
}
