-- Создание схемы основной базы данных --
create schema main;

--     Создание таблиц для осуществления авторизации     --
-- Таблица для хранения данных позволяющих произвести авторизацию --
create table main.Users(
id serial primary key,		-- ID пользователя в приложении 
login varchar(30) not null, -- Логин пользователя в Менеджере паролей
pass varchar(30) not null); -- Пароль пользователя в Менеджере паролей

-- Таблица с указанием роли пользователя (user - обычный пользователь, super - Пользователь с расширенными правами) --
-- Для определения роли пользователя используется перечислямый тип enum --
create type user_type AS ENUM ('user', 'super');

create table main.uTypes(
id int not null primary key references main.Users on delete cascade, -- связь 1 к 1 с таблицей Users
u_type user_type default 'user');

-- Создание таблицы PassID - в ней создаётся уникальный ID для каждого пароля (Имя пользователя и название ресурса) --
create table main.PassID(
pID serial primary key, -- ID пароля --
UserId int not null references main.Users, -- ID пользователя
Resource varchar(50) not null); -- Название ресурса на пароль от которого польщзователь сохраняет --

-- Таблица с основной информацией - логинами и пароями пользователей --
create table main.Passwords(
PID int primary key references main.PassID, -- ID пароля --
login varchar(30) not null, -- логин --
pass varchar(30) not null); -- пароль

-- Таблица со спец. данными недоступным обычным пользователям --
create table spec_info(
PID int primary key references main.PassID,-- какой пароль --
add_date time default current_time, -- когда был добавлен --
last_use time default current_time); -- когда использовался последний раз --

--     Создание функций и процедур для работы с таблицами БД     --

--  Процедуры добавления данных  --

-- Добавление нового Пользователя --
create or replace procedure Add_new_user(ul varchar(30), up varchar(30)) -- ul - user login; up - user password; --
language sql 
as $$
insert into main.Users (login, pass)
values(ul, up);
$$
-- Вызов для проверки работоспособности -- 
call Add_new_user('Ivan', 'ivan1234');

-- Добавление нового пароля --
create or replace procedure Add_new_password(uID int, res varchar(50)) -- uID - user ID; res - resource
language sql 
as $$
insert into main.PassID (UserId, Resource)
values (uID, res);
$$
-- Вызов для проверки работоспособности -- 
call add_new_password(1, 'Site_1');

-- Добавление логина и пороля в БД --
create or replace procedure Add_pass_data(pid int, l varchar(30), p varchar(30))
language sql 
as $$
insert into main.Passwords (PID, login, pass)
values (pid, l, p);
$$
-- Вызов для проверки работоспособности -- 
call add_pass_data(1, 'ivan11', 'i1v2a3n4');

-- Итоговая процедура добавления пароля --
create or replace procedure add_pass(username varchar(30), res varchar(50), l varchar(30), p varchar(30)) 
as $$
declare 
uid int;
begin
uid = (select id from main.users
where main.users.login = username);
call add_new_password(uid, res) ;
call add_pass_data (get_passid(username, res), l, p);
end;
$$ language plpgsql


-- Функция возвращающая все пароли пользователя --
create or replace function All_user_passwords(username varchar(30)) -- получает имя пользователя --
returns table  (Resource varchar(50), Login varchar(30), Pass varchar(30))
as $$
begin
	-- возвращает таблицу Ресурс\Логин\Пароль для переданного пользователя --
	return query
	select PassID.resource as "Resource", passwords.login as "Login", passwords.pass as "Pass" 
	from main.PassId
	join  main.passwords on
	PassId.pid = passwords.pid
	where main.passid.userid = (
	select id from main.users 
	where main.users.login = username);
end;
$$ language plpgsql;
-- Вызов для проверки работоспособности --
select * from all_user_passwords('Ivan');
	
-- Функция возвращающая Логин и пароль по Имени пользователя и названию ресурса -- 
create or replace function main.Find_pass(username varchar(30), res varchar(50))
returns table ("Login" varchar(30), "Password" varchar(30))
as $$
begin

-- Создаётся временная таблица в которую добавляются все пароли пользователя --
create local temp table if not exists temp_table(
Resource varchar(50), 
Login varchar(30), 
Pass varchar(30))
on commit drop; -- Таблица удаляется при завершении работы функции -- 

insert into temp_table (Resource, Login, Pass)
select * from all_user_passwords(username);

-- Выбираем из временной таблицы нужный логин и пароль по введенному названию ресурса -- 
	return query
	select Login as "Login", Pass as "Password" from temp_table
	where temp_table.Resource = res;
end;
$$ language plpgsql;
-- Вызов для проверки работоспособности --
select * from Find_pass('Ivan', 'Site_1');

-- Функция, возвращающая Id пароля по имени пользователя и названию ресурса --
create or replace function Get_PassId(username varchar(30), res varchar(50)) returns int
as $$
begin
	return(
	select pID from main.PassId
	where main.PassId.userid  = (
	select id from main.users 
	where main.users.login = username
	) and 
	main.passid.resource = res);
end;
$$ language plpgsql;

-- Удаление пароля из бд--
create or replace procedure Delete_pass(username varchar(30), res varchar(50))
language sql 
as $$
delete from main.passwords
where main.passwords.pid = (select Get_PassId(username, res))
$$

-- Триггер на добавление нового пользователя --
create or replace function New_user(cu varchar(30), ul varchar(30), up varchar(30)) returns trigger
-- ul - user login; 
-- up - user password; 
-- cu - current user;
as $tr_new_user$
declare 
cut varchar(30); -- current user type;
begin 
	cut = (select u_type from main.utypes 
	join main.users on main.users.id  = main.utypes.id 
	where main.users.login = cu)
	if cut = 'super' then 
	
	
end
$tr_new_user$ language plpgsql;

-- Добавление данных для тестового запуска --
call add_new_user('petr', 'p1e2t3r4');
call add_pass('Ivan', 'Rustore', 'ivan1980', 'pass1234');
call add_pass('petr', 'habr', 'petya_go', '0089ppp');
call add_pass('petr', 'skisport', 'user_petya', '0089ski');
call add_pass('Ivan', 'github', 'python_progger', 'pyt101010');



