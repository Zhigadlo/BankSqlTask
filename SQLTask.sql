--task1(db structure creation)
------------------------------------------------
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
	Number varchar(16) not null unique,
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
------------------------------------------------

--task9
------------------------------------------------
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
on Cards 
for insert, update
as
begin 
	declare @AccountBalance money, @CardsAccountBalance money, @AccountId int
	
	declare cur cursor for  
	select AccountId from inserted

	open cur
	fetch next from cur 
	into @AccountId
	
	while @@fetch_status = 0
	begin
		select @AccountBalance = a.Balance, @CardsAccountBalance = Sum(c.Balance)
		from Accounts as a
		join Cards as c on c.AccountId = a.Id
		where a.Id = @AccountId
		group by a.Balance

		if @AccountBalance < @CardsAccountBalance
		begin
			print 'You have not enough money';
			rollback transaction
		end

		fetch next from cur into @AccountId
	end
	close cur
end
go
------------------------------------------------

--task1(tables filling)
------------------------------------------------
--many tables filling
insert SocialStates values ('student'), ('pensioner'), ('disabled'), ('veteran'), ('worker')
insert Cities values ('Minsk'), ('Gomel'), ('Mozyr'), ('Zhitomir'), ('Brest')
insert Banks values ('Alfa-bank'), ('Belarusbank'), ('Belinvestbank'), ('Razvodilovobank'), ('MTB-bank')

declare @i int, @tableItemsCount int

set @i = 1;
set @tableItemsCount = 5;

--one to many tables filling
while @i <= @tableItemsCount
begin
	insert Clients values ('Fullname' + convert(varchar, @i), (select top 1 Id from SocialStates order by newid()))
	insert Accounts values ((select top 1 Id from Clients order by newid()), (select top 1 Id from Banks order by newid()), @i * 1000)
	insert Cards values ('number' + convert(varchar, @i), @i, @i*500)
	insert BankBranches values('branch' + convert(varchar, @i), (select top 1 Id from Banks order by newid()))
	set @i = @i + 1
end

set @i = 1

--many to many table filling
while @i <= @tableItemsCount
begin 
	insert CityBankBranches values ((select top 1 Id from Cities order by newid()),
									(select top 1 Id from BankBranches order by newid()));
	set @i = @i + 1;
end

go
------------------------------------------------

--task2
------------------------------------------------
select distinct b.Name from BankBranches as bb 
join Banks as b on b.Id = bb.BankId
join CityBankBranches as cbb on bb.Id = cbb.BankBranchId
join Cities as c on c.Id = cbb.CityId
where c.Name = 'Gomel'
------------------------------------------------