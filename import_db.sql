PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body VARCHAR(255),
    user_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows(
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies(
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    parent_id INTEGER,
    user_id INTEGER NOT NULL,
    body VARCHAR(255),

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (parent_id) REFERENCES replies(id),
    FOREIGN KEY (user_id) REFERENCES users(id)    
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT INTO 
    users (fname, lname)
VALUES
    ('Ned', 'Johnson'),
    ('Dave', 'Johnson');

INSERT INTO
    questions (title, body, user_id)
VALUES
    (
        'Ned Question',
        'Where is the AppAcademy Office?',
        (SELECT id FROM users WHERE fname = 'Ned' AND lname = 'Johnson')
    );

INSERT INTO
    replies (question_id, parent_id, user_id, body)
VALUES
    (
        (SELECT id FROM questions where title = 'Ned Question'), 
        null,
        (SELECT id FROM users WHERE fname = 'Dave' AND lname = 'Johnson'),
        '825 Battery'
    );

INSERT INTO
    question_follows (question_id, user_id)
VALUES
    (
        (SELECT id FROM questions where title = 'Ned Question'),
        (SELECT id FROM users WHERE fname = 'Ned' AND lname = 'Johnson')
    ),
    (
        (SELECT id FROM questions where title = 'Ned Question'),
        (SELECT id FROM users WHERE fname = 'Dave' AND lname = 'Johnson')
    );

INSERT INTO
    question_likes (question_id, user_id)
VALUES
    (
        (SELECT id FROM questions where title = 'Ned Question'),
        (SELECT id FROM users WHERE fname = 'Ned' AND lname = 'Johnson')
    ),
    (
        (SELECT id FROM questions where title = 'Ned Question'),
        (SELECT id FROM users WHERE fname = 'Dave' AND lname = 'Johnson')
    );




