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
	Balance money default 0,
	constraint FK_Accounts_To_Clients foreign key(ClientId) references Clients(Id) on delete cascade,
	constraint FK_Accounts_To_Banks foreign key(BankId) references Banks(Id) on delete cascade
);

create table Cards
(
	Id int primary key identity(1, 1),
	Number varchar(16) not null,
	AccountId int not null,
	Balance money default 0,
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

go

create trigger Accounts_Update
on Accounts 
for update
as
begin 
	if update(Balance)
	begin
		declare @AccountBalance money, @CardsAccountBalance money
		
		select @AccountBalance = inserted.Balance, @CardsAccountBalance = Sum(c.Balance)
		from inserted
		join Cards as c on inserted.Id = c.AccountId
		group by inserted.Balance

		if @AccountBalance < @CardsAccountBalance
		begin
			rollback transaction
			print 'There is not enough money'
		end
	end
end

go

create trigger Cards_Insert_Update
on Accounts 
for insert, update
as
begin 
	
	declare @AccountBalance money, @CardsAccountBalance money, @AccountId int
	
	open cur
	fetch next into @AccountId
	while @@fetch_status = 0
	begin
		select @AccountBalance = a.Balance, @CardsAccountBalance = Sum(c.Balance)
		from Accounts as a
		join Accounts as c on inserted.Account = c.Id
		group by inserted.Balance

		if @AccountBalance < @CardsAccountBalance
		begin
			rollback transaction
			print 'You have not enough money on the card with id=' + convert(nvarchar, inserted.Id);
		end

		fetch next from cur into @AccountId
	end
end
go



