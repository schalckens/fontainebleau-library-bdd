
-- Création de la structure de la base (tables)
CREATE TABLE "User" (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    isBanned BOOLEAN NOT NULL
);

CREATE TABLE Admin (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL
);

CREATE TABLE Banishment (
    id SERIAL PRIMARY KEY,
    id_Admin INT NULL,
    id_User INT NOT NULL,
    description TEXT NOT NULL,
    dateStart DATE NOT NULL,
    dateEnd DATE NULL,
    FOREIGN KEY (id_Admin) REFERENCES Admin(id),
    FOREIGN KEY (id_User) REFERENCES "User"(id)
);

CREATE TABLE Penalty (
    id SERIAL PRIMARY KEY,
    id_Admin INT NOT NULL,
    id_User INT NOT NULL,
    description TEXT NOT NULL,
    dateStart DATE NOT NULL,
    dateEnd DATE NOT NULL,
    FOREIGN KEY (id_Admin) REFERENCES Admin(id),
    FOREIGN KEY (id_User) REFERENCES "User"(id)
);

CREATE TABLE State_Type (
    id SERIAL PRIMARY KEY,
    condition VARCHAR(255) NOT NULL
);

CREATE TABLE Edition (
    id SERIAL PRIMARY KEY,
    companyName VARCHAR(255) NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE Book_Infos (
    id SERIAL PRIMARY KEY,
    id_Edition INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    numberOfPages INT NOT NULL,
    summary TEXT NOT NULL,
    FOREIGN KEY (id_Edition) REFERENCES Edition(id)
);

CREATE TABLE Book (
    id SERIAL PRIMARY KEY,
    id_BookInfos INT NOT NULL,
    FOREIGN KEY (id_BookInfos) REFERENCES Book_Infos(id)
);

CREATE TABLE Log_State (
    id SERIAL PRIMARY KEY,
    id_Admin INT NOT NULL,
    id_stateType INT NOT NULL,
    id_Book INT NOT NULL,
    description TEXT NOT NULL,
    dateEntry DATE NOT NULL,
    FOREIGN KEY (id_Admin) REFERENCES Admin(id),
    FOREIGN KEY (id_stateType) REFERENCES State_Type(id),
    FOREIGN KEY (id_Book) REFERENCES Book(id)
);

CREATE TABLE Borrow_Type (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    numberOfDays INT NOT NULL
);

CREATE TABLE Log_Borrowing (
    id SERIAL PRIMARY KEY,
    id_User INT NOT NULL,
    id_BorrowType INT NOT NULL,
    id_Book INT NOT NULL,
    dateEntry DATE NOT NULL,
    isReturned BOOLEAN NOT NULL,
    FOREIGN KEY (id_User) REFERENCES "User"(id),
    FOREIGN KEY (id_BorrowType) REFERENCES Borrow_Type(id),
    FOREIGN KEY (id_Book) REFERENCES Book(id)
);

CREATE TABLE Author (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    description TEXT NOT NULL
);

CREATE TABLE Writer (
    id_Author INT NOT NULL,
    id_BookInfos INT NOT NULL,
    PRIMARY KEY (id_Author, id_BookInfos),
    FOREIGN KEY (id_Author) REFERENCES Author(id),
    FOREIGN KEY (id_BookInfos) REFERENCES Book_Infos(id)
);

CREATE TABLE Tag (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE Contents (
    id_Tag INT NOT NULL,
    id_BookInfos INT NOT NULL,
    PRIMARY KEY (id_Tag, id_BookInfos),
    FOREIGN KEY (id_Tag) REFERENCES Tag(id),
    FOREIGN KEY (id_BookInfos) REFERENCES Book_Infos(id)
);
--Création des fonctions

-- Fonction checkPenaltyAndBanish
CREATE FUNCTION checkPenaltyAndBanish(idUser INT) RETURNS VOID AS
$$
DECLARE
    penaltyCount INT;
    hasExistingBanishment BOOLEAN;
BEGIN
    -- Vérifie si l'utilisateur a déjà un bannissement en cours
    SELECT EXISTS (
        SELECT 1
        FROM banishment b
        WHERE b.id_user = idUser
        AND (b.dateEnd IS NULL OR b.dateEnd > CURRENT_DATE)
    ) INTO hasExistingBanishment;

    -- Compte le nombre d'occurrences de l'id_user dans la table penalty
    SELECT COUNT(*) INTO penaltyCount
    FROM penalty p
    WHERE p.id_user = idUser
    AND p.dateEnd > CURRENT_DATE;

    -- Si le nombre d'occurrences est égal à 3 pour des pénalités valides
    IF penaltyCount = 3 AND NOT hasExistingBanishment THEN
        -- Ajoute une ligne dans la table banishment
        INSERT INTO banishment (id_user, description, dateStart, dateEnd)
        VALUES (idUser, '3 pénalités', CURRENT_DATE, CURRENT_DATE + INTERVAL '1' MONTH);

        -- Met à jour le statut isBanned de l'utilisateur dans la table user à true
        UPDATE "User"
        SET isBanned = true
        WHERE id = idUser;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- Fonction unbanUsers
CREATE FUNCTION unbanUsers() RETURNS VOID AS
$$
BEGIN
    -- Met à jour le statut isBanned des utilisateurs bannis dont la période de bannissement est expirée
    UPDATE "User"
    SET isBanned = false
    WHERE isBanned = true
    AND id IN (
        SELECT id_user
        FROM banishment
        WHERE dateEnd < CURRENT_DATE
    );
END;
$$ LANGUAGE plpgsql;


--Création des triggers

CREATE FUNCTION update_penalty_and_banish()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM checkPenaltyAndBanish(NEW.id_User);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER penalty_trigger
AFTER INSERT ON Penalty
FOR EACH ROW
EXECUTE FUNCTION update_penalty_and_banish();


CREATE OR REPLACE FUNCTION trigger_unbanUsers()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM unbanUsers();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_unbanUsers
BEFORE INSERT ON Log_borrowing
FOR EACH ROW EXECUTE FUNCTION trigger_unbanUsers();



-- Contraintes particulières
ALTER TABLE Banishment
    ALTER COLUMN id_User SET NOT NULL;
	
ALTER TABLE Penalty
    ALTER COLUMN id_User SET NOT NULL;

ALTER TABLE Banishment
ADD CHECK (dateEnd > dateStart OR dateEnd IS NULL);

-- Contraintes de vérification (CHECK constraints)
ALTER TABLE State_Type
ADD CONSTRAINT check_state_condition CHECK (condition IN ('N', 'VG', 'G', 'O', 'B', 'VB'));

ALTER TABLE Borrow_Type
ADD CONSTRAINT check_borrow_description CHECK (description IN ('R', 'B', 'E', 'L'));

-- Insertion de données de test

INSERT INTO "User" (name, surname, email, password, isBanned)
VALUES
    ('Léa', 'Lefebvre', 'lea@example.com', 'leapasse', FALSE),
    ('Hugo', 'Mercier', 'hugo@example.com', 'hugopasse', TRUE),
    ('Clara', 'Giroux', 'clara@example.com', 'clarapasse', FALSE),
	('Romain', 'Renaud', 'romain@example.com', 'romainpasse', FALSE),
    ('Margaux', 'Caron', 'margaux@example.com', 'margauxpasse', FALSE),
    ('Sébastien', 'Léonard', 'sebastien@example.com', 'sabastienpasse', FALSE),
	('Lola', 'Moreau', 'lola@example.com', 'lolapasse', FALSE),
    ('Alexandre', 'Picard', 'alexandre@example.com', 'alexandrepasse', FALSE),
    ('Charlotte', 'Dufresne', 'charlotte@example.com', 'charlottepasse', FALSE),
	('Tristan', 'Girard', 'tristan@example.com', 'tristanpasse', FALSE),
    ('Emma', 'Roux', 'emma@example.com', 'motdepasse23', FALSE),
    ('Nicolas', 'Boucher', 'nicolas@example.com', 'nicolaspasse', FALSE),
	('Antoine', 'Lefevre', 'antoine@example.com', 'antoinepasse', FALSE),
    ('Camille', 'Dubois', 'camille@example.com', 'camillepasse', FALSE),
    ('Juliette', 'Girard', 'juliette@example.com', 'juliettepasse', FALSE),
	('Lucas', 'Martin', 'lucas@example.com', 'lucaspasse', FALSE),
    ('Chloé', 'Leroux', 'chloe@example.com', 'chloepasse', FALSE),
    ('Gabriel', 'Fournier', 'gabriel@example.com', 'gabrielpasse', FALSE),
	('Eléna', 'Lemaire', 'elena@example.com', 'elenapasse', FALSE),
    ('Louis', 'Dupont', 'louis@example.com', 'louispasse', FALSE),
    ('Aurélie', 'Roussel', 'aurelie@example.com', 'aureliepasse', FALSE),
	('Théo', 'Gagnon', 'theo@example.com', 'theopasse', FALSE),
    ('Manon', 'Lévesque', 'manon@example.com', 'manonpasse', FALSE),
    ('Jules', 'Bergeron', 'jules@example.com', 'julespasse', FALSE),
	('Mélissa', 'Ferland', 'melissa@example.com', 'melissapasse', FALSE),
    ('Vincent', 'Gauthier', 'vincent@example.com', 'vincentpasse', FALSE),
    ('Élodie', 'Lavoie', 'elodie@example.com', 'elodiepasse', FALSE),
	('Marie', 'Martin', 'mariemartin@example.com', 'marie123', FALSE),
    ('Paul', 'Dupont', 'pauldupont@example.com', 'paul456', FALSE),
    ('Lucie', 'Lefevre', 'lucielefevre@example.com', 'lucie789', FALSE);


INSERT INTO Admin (name, surname, email, password)
VALUES
    ('Gerard', 'Rade', 'gerardrade@example.com', 'adminpassword1'),
    ('Jacques', 'Fourrier', 'jacquesfourrier@example.com', 'adminpassword2'),
	('Sophie', 'Leclerc', 'sophieleclerc@example.com', 'sophieadmin1'),
    ('Pierre', 'Lemoine', 'pierrelemoine@example.com', 'pierreadmin2');


INSERT INTO Banishment (id_Admin, id_User, description, dateStart, dateEnd)
VALUES
    (1, 2, '3 Pénalités', '2023-10-11', '2023-11-30');
	
INSERT INTO Penalty (id_Admin, id_User, description, dateStart, dateEnd)
VALUES
    (1, 2, 'Dégradation d''emprunt', '2023-09-24', '2023-10-24'),
	(1, 2, 'Retard de rendu d''emprunt', '2023-09-30', '2023-10-30'),
	(1, 2, 'Dégradation d''emprunt', '2023-10-11', '2023-11-11');


INSERT INTO State_Type (condition)
VALUES
    ('N'),
    ('VG'),
    ('G'),
    ('O'),
    ('B'),
    ('VB');
	
INSERT INTO Edition (companyName, description)
VALUES
    ('Table Ronde', 'L''Édition Table Ronde est une maison d''édition française prestigieuse, fondée en 1944, qui se spécialise dans la publication de littérature générale, de fiction, de poésie et de textes philosophiques. Elle est renommée pour sa contribution à la littérature contemporaine.'),
    ('Librio', 'Librio a été créé en mars 1994 par les éditions J''ai lu. Le principe est de proposer au plus grand nombre des œuvres littéraires, classiques ou contemporaines, au prix unique de 10 francs. Les livres sont actuellement vendus 2€ pour les classiques, 3€ ou 5€ pour les inédits (ainsi que les documents et les mémos)'),
	('Gallimard', 'Les éditions Gallimard sont une maison d''édition française fondée en 1911 par Gaston Gallimard, spécialisée dans la littérature générale et la traduction de nombreux auteurs étrangers.'),
    ('Folio', 'Folio est une collection de poche créée en 1972 au sein des éditions Gallimard. Elle propose des ouvrages de la littérature mondiale, de la philosophie, des sciences humaines, ainsi que des ouvrages de référence dans divers domaines.');


INSERT INTO Book_Infos (id_Edition, title, numberOfPages, summary)
VALUES
    (1, 'Antigone', 128, 'Fille d''Oedipe et de Jocaste, la jeune Antigone est en révolte contre la loi humaine qui interdit d''enterrer le corps de son frère Polynice. Présentée sous l''Occupation, en 1944, l''Antigone d''Anouilh met en scène l''absolu d''un personnage en révolte face au pouvoir, à l''injustice et à la médiocrité.'),
    (2, 'Cyrano de Bergerac', 284, 'Provoqué par un fâcheux, Cyrano se moque audacieusement de lui-même et de son nez, objet de sa disgrâce. Séduire Roxane ? Il n''ose y songer. Mais puisqu''elle aime Christian, un cadet de Gascogne qui brille plus par son apparence que par ses reparties, pourquoi ne pas tenter une expérience ? "Je serai ton esprit, tu seras ma beauté", dit Cyrano à son rival. "Tu marcheras, j''irai dans l''ombre à ton côté." Jeu étrange et dangereux. Christian ne s''y trompe pas ; à travers lui, la belle Roxane en aime un autre. Mais Cyrano, s''il entrevoit le bonheur un instant, ne peut oublier son physique ingrat.'),
	(3, 'Le Petit Prince', 96, 'Le Petit Prince est un roman poétique et philosophique écrit par Antoine de Saint-Exupéry. Il raconte l''histoire d''un petit prince venu d''une autre planète, qui rencontre un aviateur échoué dans le désert du Sahara.'),
	(1, 'Le Comte de Monte-Cristo', 1235, 'Le Comte de Monte-Cristo est un roman d''aventures et d''intrigues écrit par Alexandre Dumas. Il raconte l''histoire d''Edmond Dantès, un marin injustement emprisonné qui s''évade et cherche à se venger de ceux qui l''ont trahi.'),
    (2, 'Orgueil et Préjugés', 432, 'Orgueil et Préjugés est un roman de la romancière anglaise Jane Austen. Il raconte l''histoire d''Elizabeth Bennet et de sa relation avec Mr. Darcy, un riche gentleman.'),
	(1, 'Les Misérables', 1488, 'Les Misérables est un roman de Victor Hugo. Il raconte l''histoire de Jean Valjean, un homme condamné pour avoir volé du pain pour nourrir sa famille. Après avoir été libéré de prison, il cherche la rédemption et une nouvelle vie malgré la persécution de l''inspecteur Javert.');


INSERT INTO Book (id_BookInfos)
VALUES
    (1),
    (2),
    (3),
	(4),
	(5),
	(6);


INSERT INTO Log_State (id_Admin, id_stateType, id_Book, description, dateEntry)
VALUES
    (1, 1, 1, 'Le livre est neuf.', '2023-11-09'),
    (2, 6, 2, 'Le livre est abimé : tâches de café et pages arrachées.', '2023-11-09'),
    (3, 5, 5, 'Le livre a des pages avec des dessins.', '2023-11-09'),
    (4, 2, 4, 'Le livre a été emprunté une fois.', '2023-11-09');
	
	
INSERT INTO Borrow_Type (description, numberOfDays)
VALUES
    ('R', 7),
    ('B', 14),
    ('E', 21),
    ('L', 7);


INSERT INTO Log_Borrowing (id_User, id_BorrowType, id_Book, dateEntry, isReturned)
VALUES
    (2, 1, 1, '2023-09-02', FALSE),
    (2, 2, 1, '2023-09-05', FALSE),
	(2, 4, 1, '2023-09-30', TRUE),
    (2, 2, 2, '2023-09-15', FALSE),
	(2, 2, 2, '2023-09-24', TRUE),
	(2, 2, 3, '2023-10-02', FALSE),
	(2, 2, 3, '2023-10-11', TRUE),
	(1, 2, 4, '2023-11-18', FALSE),
	(3, 1, 5, '2023-11-24', FALSE);


INSERT INTO Author (name, surname, description)
VALUES
    ('Jean', 'Anouilh', 'Dramaturge français du 20e siècle, célèbre pour ses pièces théâtrales, dont "Antigone", réinterprétation moderne de la tragédie classique.'),
    ('Edmond', 'Rostand', 'Auteur français du 19e siècle, surtout connu pour sa pièce emblématique "Cyrano de Bergerac". Sa plume poétique et son talent théâtral ont laissé une marque durable dans la littérature française.'),
	('Antoine', 'de Saint-Exupéry', 'Écrivain et aviateur français, célèbre pour son ouvrage "Le Petit Prince".'),
    ('Victor', 'Hugo', 'Écrivain, poète et dramaturge français du XIXe siècle, auteur de "Les Misérables" et "Notre-Dame de Paris".'),
	('Alexandre', 'Dumas', 'Écrivain français du XIXe siècle, auteur du célèbre roman "Le Comte de Monte-Cristo" et de "Les Trois Mousquetaires".'),
	('Jane', 'Austen', 'Romancière anglaise du XIXe siècle, connue pour ses œuvres littéraires classiques telles que "Orgueil et Préjugés" et "Raison et Sentiments".');
	
	
INSERT INTO Writer (id_Author, id_BookInfos)
VALUES
    (1, 1),
    (2, 2),
	(3, 3),
	(4, 6),
	(5, 4),
	(6, 5);


INSERT INTO Tag (description)
VALUES
    ('Drame'),
    ('Tragédie'),
	('Classique'),
    ('Aventure');


INSERT INTO Contents (id_Tag, id_BookInfos)
VALUES
    (2, 1),
	(3, 1),
    (3, 2),
    (4, 2),
	(3, 3),
	(4, 3),
	(1, 4),
	(4, 4),
	(1, 5),
	(3, 5),
	(2, 6),
	(3, 6);


-- Autres contraintes ajoutées après insertion des données test 

CREATE OR REPLACE FUNCTION set_dateEntry() RETURNS TRIGGER AS $$
BEGIN
    NEW.dateEntry := CURRENT_DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_set_dateEntry
BEFORE INSERT ON Log_borrowing
FOR EACH ROW EXECUTE FUNCTION set_dateEntry();

CREATE OR REPLACE FUNCTION set_dates_log_state() RETURNS TRIGGER AS $$
BEGIN
    NEW.dateEntry := CURRENT_DATE; -- Définit la date d'entrée du log comme la date actuelle
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_dates_trigger_log_state
BEFORE INSERT ON Log_State
FOR EACH ROW EXECUTE FUNCTION set_dates_log_state();

-- Création du déclencheur pour mettre à jour dateStart à CURRENT_DATE lors d'une insertion
CREATE OR REPLACE FUNCTION set_dateStart_Penalty()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dateStart := CURRENT_DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du déclencheur pour utiliser la fonction lors de l'insertion
CREATE TRIGGER before_insert_Penalty
BEFORE INSERT ON Penalty
FOR EACH ROW EXECUTE FUNCTION set_dateStart_Penalty();

-- Création du déclencheur pour mettre à jour dateStart à CURRENT_DATE lors d'une insertion
CREATE OR REPLACE FUNCTION set_dateStart_Banishment()
RETURNS TRIGGER AS $$
BEGIN
    NEW.dateStart := CURRENT_DATE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du déclencheur pour utiliser la fonction lors de l'insertion
CREATE TRIGGER before_insert_Banishment
BEFORE INSERT ON Banishment
FOR EACH ROW EXECUTE FUNCTION set_dateStart_Banishment();


