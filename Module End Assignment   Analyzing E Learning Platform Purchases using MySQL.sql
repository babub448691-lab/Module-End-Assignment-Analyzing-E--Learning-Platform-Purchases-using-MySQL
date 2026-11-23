-- Module-End Assignment: Analyzing E-Learning Platform Purchases (MySQL)
-- Tables: learners, courses, purchases
-- Run the whole script top to bottom in MySQL Workbench (MySQL 8.0.16+)



 
-- TASK 1: CREATE THE DATABASE AND SCHEMA, POPULATE THE SCHEMA
                                                                                                                                                                                                                                           

DROP DATABASE IF EXISTS elearning_db;
CREATE DATABASE elearning_db;
USE elearning_db;

-- 1.1 learners
CREATE TABLE learners (
    learner_id  INT           NOT NULL AUTO_INCREMENT,
    full_name   VARCHAR(100)  NOT NULL,
    country     VARCHAR(50)   NOT NULL,
    PRIMARY KEY (learner_id)
);

-- 1.2 courses
CREATE TABLE courses (
    course_id    INT            NOT NULL AUTO_INCREMENT,
    course_name  VARCHAR(100)   NOT NULL,
    category     VARCHAR(50)    NOT NULL,
    unit_price   DECIMAL(10,2)  NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (course_id)
);

-- 1.3 purchases (links learners and courses)
CREATE TABLE purchases (
    purchase_id    INT   NOT NULL AUTO_INCREMENT,
    learner_id     INT   NOT NULL,
    course_id      INT   NOT NULL,
    quantity       INT   NOT NULL CHECK (quantity > 0),
    purchase_date  DATE  NOT NULL,
    PRIMARY KEY (purchase_id),
    CONSTRAINT fk_purchases_learner FOREIGN KEY (learner_id) REFERENCES learners (learner_id),
    CONSTRAINT fk_purchases_course  FOREIGN KEY (course_id)  REFERENCES courses (course_id)
);

-- 1.4 Sample data: 6 learners (one has not bought anything yet)
INSERT INTO learners (learner_id, full_name, country) VALUES
(1, 'Arjun Kumar',   'India'),
(2, 'Priya Sharma',  'India'),
(3, 'Emily Johnson', 'USA'),
(4, 'Liam Smith',    'UK'),
(5, 'Sofia Garcia',  'Spain'),
(6, 'Rahul Verma',   'India');

-- 1.5 Sample data: 6 courses across 4 categories (course 106 is never bought)
INSERT INTO courses (course_id, course_name, category, unit_price) VALUES
(101, 'SQL for Beginners',          'Data Analytics', 49.99),
(102, 'Python for Data Science',    'Programming',    79.99),
(103, 'Excel Mastery',              'Data Analytics', 39.99),
(104, 'Digital Marketing Basics',   'Marketing',      59.99),
(105, 'UI/UX Design Fundamentals',  'Design',         69.99),
(106, 'Machine Learning Intro',     'Programming',    99.99);

-- 1.6 Sample data: 8 purchase records
INSERT INTO purchases (purchase_id, learner_id, course_id, quantity, purchase_date) VALUES
(1, 1, 101, 2, '2025-01-10'),
(2, 1, 102, 1, '2025-01-25'),
(3, 2, 101, 1, '2025-02-05'),
(4, 3, 103, 3, '2025-02-18'),
(5, 3, 104, 1, '2025-03-02'),
(6, 4, 102, 2, '2025-03-15'),
(7, 5, 105, 1, '2025-03-28'),
(8, 2, 103, 2, '2025-04-04');

-- Quick check that the data loaded
SELECT * FROM learners;
SELECT * FROM courses;
SELECT * FROM purchases;


-- TASK 2: DATA EXPLORATION USING JOINS
-- (currency rounded to 2 decimals, column aliases used, sorted results)


-- 2.1 INNER JOIN: each learner's purchase details
--     (only learners who purchased, only courses that were purchased)
SELECT
    l.learner_id,
    l.full_name                                AS learner_name,
    c.course_name                              AS course_name,
    c.category                                 AS category,
    p.quantity                                 AS quantity,
    ROUND(p.quantity * c.unit_price, 2)        AS total_amount,
    p.purchase_date                            AS purchase_date
FROM purchases p
INNER JOIN learners l ON p.learner_id = l.learner_id
INNER JOIN courses  c ON p.course_id  = c.course_id
ORDER BY total_amount DESC, p.purchase_date;

-- 2.2 LEFT JOIN: all learners, including those with no purchases
--     (learners without purchases show NULL / 0)
SELECT
    l.learner_id,
    l.full_name                                          AS learner_name,
    l.country                                            AS country,
    c.course_name                                        AS course_name,
    c.category                                           AS category,
    p.quantity                                           AS quantity,
    ROUND(COALESCE(p.quantity * c.unit_price, 0), 2)     AS total_amount,
    p.purchase_date                                      AS purchase_date
FROM learners l
LEFT JOIN purchases p ON l.learner_id = p.learner_id
LEFT JOIN courses   c ON p.course_id  = c.course_id
ORDER BY l.learner_id, p.purchase_date;

-- 2.3 RIGHT JOIN: all courses, including courses nobody has purchased
SELECT
    c.course_id,
    c.course_name                              AS course_name,
    c.category                                 AS category,
    ROUND(c.unit_price, 2)                     AS unit_price,
    l.full_name                                AS learner_name,
    p.quantity                                 AS quantity,
    ROUND(p.quantity * c.unit_price, 2)        AS total_amount,
    p.purchase_date                            AS purchase_date
FROM purchases p
INNER JOIN learners l ON p.learner_id = l.learner_id
RIGHT JOIN courses  c ON p.course_id  = c.course_id
ORDER BY c.course_id, p.purchase_date;


-- TASK 3: ANALYTICAL QUERIES


-- Q1. Each learner's total spending (quantity x unit_price) with country
--     LEFT JOIN keeps learners who have not bought anything (spend = 0.00)
SELECT
    l.learner_id,
    l.full_name                                              AS learner_name,
    l.country                                                AS country,
    ROUND(COALESCE(SUM(p.quantity * c.unit_price), 0), 2)    AS total_spent
FROM learners l
LEFT JOIN purchases p ON l.learner_id = p.learner_id
LEFT JOIN courses   c ON p.course_id  = c.course_id
GROUP BY l.learner_id, l.full_name, l.country
ORDER BY total_spent DESC;

-- Q2. Top 3 most purchased courses by total quantity sold
SELECT
    c.course_id,
    c.course_name                AS course_name,
    c.category                   AS category,
    SUM(p.quantity)              AS total_quantity_sold
FROM purchases p
INNER JOIN courses c ON p.course_id = c.course_id
GROUP BY c.course_id, c.course_name, c.category
ORDER BY total_quantity_sold DESC, c.course_name
LIMIT 3;

-- Q3. Each category's total revenue and number of unique learners
SELECT
    c.category                                       AS category,
    ROUND(SUM(p.quantity * c.unit_price), 2)         AS total_revenue,
    COUNT(DISTINCT p.learner_id)                     AS unique_learners
FROM purchases p
INNER JOIN courses c ON p.course_id = c.course_id
GROUP BY c.category
ORDER BY total_revenue DESC;

-- Q4. Learners who purchased courses from more than one category
SELECT
    l.learner_id,
    l.full_name                      AS learner_name,
    l.country                        AS country,
    COUNT(DISTINCT c.category)       AS categories_purchased
FROM learners l
INNER JOIN purchases p ON l.learner_id = p.learner_id
INNER JOIN courses   c ON p.course_id  = c.course_id
GROUP BY l.learner_id, l.full_name, l.country
HAVING COUNT(DISTINCT c.category) > 1
ORDER BY categories_purchased DESC, learner_name;

-- Q5. Courses that have not been purchased at all
SELECT
    c.course_id,
    c.course_name                    AS course_name,
    c.category                       AS category,
    ROUND(c.unit_price, 2)           AS unit_price
FROM courses c
LEFT JOIN purchases p ON c.course_id = p.course_id
WHERE p.purchase_id IS NULL
ORDER BY c.course_id;

