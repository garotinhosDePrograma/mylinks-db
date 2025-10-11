create database if not exists MyLinks;

use MyLinks;

create table if not exists usuarios (
	id int auto_increment primary key,
    username varchar(255) unique,
    email varchar(255) unique,
    senha varchar(255) not null,
    foto_perfil varchar(255)
);

create table if not exists links (
	id int auto_increment primary key,
    usuario_id int,
    titulo varchar(100),
    url varchar(150),
    ordem int,
    foreign key (usuario_id) references usuarios(id) on delete cascade
);