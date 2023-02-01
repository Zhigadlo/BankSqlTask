create database BankSystem;
go
use BankSystem;

create table Cities
(
	Id int primary key identity(1, 1),
	Name varchar(20) unique
);

create table Banks
(
	Id int primary key identity(1, 1),
	Name varchar(20) unique
);

create table SocialStates
(
	Id int primary key identity(1, 1),
	Name varchar(20) unique
);

create table Clients
(
	Id int primary key identity(1, 1),
	FullName varchar(20) unique,
	SocialStateId int not null
	constraint FK_Clients_To_SocialStates foreign key(SocialStateId) references SocialStates(Id) on delete cascade
);

create table Accounts
(
	Id int primary key identity(1, 1),
	ClientId int not null,
	BankId int not null,
	constraint FK_Accounts_To_Clients foreign key(ClientId) references Clients(Id) on delete cascade,
	constraint FK_Accounts_To_Banks foreign key(BankId) references Banks(Id) on delete cascade
);

create table Cards
(
	Id int primary key identity(1, 1),
	Number varchar(16) not null,
	AccountId int not null,
	constraint FK_Cards_To_Accounts foreign key(AccountId) references Accounts(Id) on delete cascade
);

create table BankBranches
(
	Id int primary key identity(1, 1),
	Name varchar(20),
	BankId int not null,
	constraint FK_BankBranches_To_Banks foreign key(BankId) references Banks(Id) on delete cascade
);

create table CityBankBranches
(
	Id int primary key identity(1, 1),
	CityId int not null,
	BankBranchId int not null,
	constraint FK_CityBankBranches_To_Cities foreign key(CityId) references Cities(Id) on delete cascade,
	constraint FK_CityBankBranches_To_BankBranches foreign key(BankBranchId) references BankBranches(Id) on delete cascade
);
