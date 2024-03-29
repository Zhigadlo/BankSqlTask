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

--task3
------------------------------------------------
select clt.FullName as 'Client name', crd.Balance as 'Balance', bnk.Name as 'Bank' 
from Cards as crd
join Accounts as acc on acc.Id = crd.AccountId
join Banks as bnk on bnk.Id = acc.BankId
join Clients as clt on clt.Id = acc.ClientId
------------------------------------------------

--task4
------------------------------------------------
select clt.FullName as 'Client', Sum(crd.Balance) as 'Cards balance', acc.Balance as 'Account balance' 
from Accounts as acc 
join Clients as clt on clt.Id = acc.ClientId
join Cards as crd on crd.AccountId = acc.Id
group by acc.Balance, clt.FullName
having Sum(crd.Balance) < acc.Balance
------------------------------------------------

--task 5(group by realisation)
------------------------------------------------
select socSt.Name as 'Social state', Count(crd.Id) as 'Cards count'
from Accounts as acc 
join Clients as clt on clt.Id = acc.ClientId
join Cards as crd on crd.AccountId = acc.Id
right join SocialStates as socSt on clt.SocialStateId = socSt.Id
group by socSt.Name
------------------------------------------------

-- task5(sub query realisation)
------------------------------------------------
select s.Name as 'Social state', (select Count(*) from Cards as crd 
								  join Accounts as acc on acc.Id = crd.AccountId 
								  join Clients as clt on acc.ClientId = clt.Id
								  where clt.SocialStateId = s.Id) as 'Cards count'
from SocialStates as s
order by s.Name
------------------------------------------------

go

--task6 
------------------------------------------------
create procedure AddMoneyToSocialState
@socialStateId int
as
if exists(select 1 from SocialStates
		  where Id = @socialStateId)
begin
	update Accounts 
	set Balance = Balance + 10 
	from Accounts as acc
	join Clients as clt on clt.Id = acc.ClientId
	join SocialStates as ss on ss.Id = clt.SocialStateId
	where ss.Id = @socialStateId 
	
end
else
	print 'There is no such social state'

go

--procedure health check
declare @socialStateId int 
set @socialStateId = 5

select clt.FullName as 'Client name', acc.Balance as 'Balance'
from Accounts as acc 
join Clients as clt on acc.ClientId = clt.Id
join SocialStates as ss on ss.Id = clt.SocialStateId
where ss.Id = @socialStateId

exec AddMoneyToSocialState @socialStateId

select clt.FullName as 'Client name', acc.Balance as 'Balance'
from Accounts as acc 
join Clients as clt on acc.ClientId = clt.Id
join SocialStates as ss on ss.Id = clt.SocialStateId
where ss.Id = @socialStateId
------------------------------------------------
--task7
------------------------------------------------
select distinct clt.FullName as 'Client', (select acc.Balance - Sum(Cards.Balance) from Cards
										   join Accounts on Cards.AccountId = Accounts.Id
										   join Clients on Clients.Id = Accounts.ClientId
										   where Accounts.Id = acc.Id) as 'Free money'
from Accounts as acc
join Clients as clt on clt.Id = acc.ClientId
join Cards as crd on acc.ClientId = clt.Id
group by clt.FullName, acc.Id, acc.Balance
------------------------------------------------

--task8
------------------------------------------------
go
create procedure TransferMoneyFromAccountToCard
@accountId int,
@cardId int,
@transferAmount money
as
if not exists(select 1 from Accounts
			  where Accounts.Id = @accountId)
begin
		  print 'There is no such account'
end;
else if not exists(select 1 from Accounts
		  join Cards on Accounts.Id = Cards.AccountId
		  where Accounts.Id = @accountId and Cards.Id = @cardId)
begin
		  print 'There is no such card on this account'
end;
else
begin 

	begin transaction
		update Cards 
		set Balance = Balance + @transferAmount
		where Id = @cardId

		if(select acc.Balance - Sum(crd.Balance) from Cards as crd 
												 join Accounts as acc on acc.Id = crd.AccountId
												 where acc.Id = @accountId and crd.Id = @cardId
												 group by acc.Balance) < 0
		begin
		   print 'Not enough money';
		   rollback transaction;
		end;
	commit transaction
end;


--procedure health check
declare @accId int, @crdId int, @money money
set @accId = 1
set @crdId = 1
set @money = 60

select clt.FullName as 'Client', acc.Balance as 'Account money', crd.Balance as 'Card balance'
from Accounts as acc
join Clients as clt on clt.Id = acc.ClientId
join Cards as crd on acc.ClientId = clt.Id
where acc.Id = @accId and crd.AccountId = acc.Id

exec TransferMoneyFromAccountToCard @accId, @crdId, @money

select clt.FullName as 'Client', acc.Balance as 'Account money', crd.Balance as 'Card balance'
from Accounts as acc
join Clients as clt on clt.Id = acc.ClientId
join Cards as crd on acc.ClientId = clt.Id
where acc.Id = @accId and crd.AccountId = acc.Id
------------------------------------------------

--task9 health care
------------------------------------------------
--Accounts check

declare @id int;
set @id = 5;

select * from Accounts where Id = @id
--success case
update Accounts 
set Balance = Balance - 30
where Id = @id

select * from Accounts where Id = @id

--error case
update Accounts 
set Balance = Balance - 100000
where Id = @id

--Cards check

set @id = 5;

select acc.Balance as 'Account balance', crd.Id as 'Card id', crd.Balance as 'Card balance'
from Accounts as acc
join Cards as crd on crd.AccountId = acc.Id
where crd.Id = @id

--success case
update Cards 
set Balance = Balance + 30
where Id = @id

select acc.Balance as 'Account balance', crd.Id as 'Card id', crd.Balance as 'Card balance'
from Accounts as acc
join Cards as crd on crd.AccountId = acc.Id
where crd.Id = @id

--error case
update Cards 
set Balance = Balance + 100000
where Id = @id

------------------------------------------------