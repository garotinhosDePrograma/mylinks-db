CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE,
    email VARCHAR(255) UNIQUE,
    senha VARCHAR(255) NOT NULL,
    foto_perfil VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS links (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    titulo VARCHAR(100),
    url VARCHAR(150),
    ordem INT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
);

INSERT INTO usuarios (username, email, senha, foto_perfil) VALUES ('Harry_Potter', 'harry@gmail.com', '$2b$12$kAj9cVOnEEkq/NiYLLEuaOV3HiLbvJjmvtl12.TgDClIS.hA8tP.y', '');
INSERT INTO usuarios (username, email, senha, foto_perfil) VALUES ('Peter_Parker', 'peter@gmail.com', '$2b$12$edPeHGSGR7d33sc6oEGbMuhLYAfw62KYsFZXn7zBX0C8JC82VCElq', '');
INSERT INTO usuarios (username, email, senha, foto_perfil) VALUES ('Tony_Stark', 'tony@hotmail.com', '$2b$12$0o/amXHJFnopEkE1oLCqaOO/PtmTRx6X0eTeWBDQllXe5rgs63bFC', '');

INSERT INTO links (usuario_id, titulo, url, ordem) VALUES (1, 'Harry Potter', 'https://m.youtube.com/watch?v=jAxvLkfeCpI&pp=0gcJCR4Bo7VqN5tD', 1);
INSERT INTO links (usuario_id, titulo, url, ordem) VALUES (2, 'Miranha', 'https://www.reddit.com/r/Spiderman/comments/t0emam/which_episode_of_spiderman_1960_is_this_meme_from/?tl=pt-br', 1);
INSERT INTO links (usuario_id, titulo, url, ordem) VALUES (3, 'Homen de Ferro', 'https://www.reddit.com/r/memes/comments/ikjsrg/i_am_iron_man/?tl=pt-br', 1);
