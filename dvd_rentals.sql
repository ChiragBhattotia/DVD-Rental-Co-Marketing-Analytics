# Data Exploration
# actor table
SELECT * 
FROM dvd_rentals.actor
LIMIT 10;
-- Number of actor_id
SELECT COUNT(DISTINCT actor_id)
FROM dvd_rentals.actor;

# category table
SELECT * 
FROM dvd_rentals.category
LIMIT 10;
-- Total categories
SELECT COUNT(DISTINCT category_id)
FROM dvd_rentals.category;

# film table
SELECT film_id, title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update
FROM dvd_rentals.film
LIMIT 10;
SELECT COUNT(DISTINCT film_id)
FROM dvd_rentals.film;

# film_actor table
SELECT *
FROM dvd_rentals.film_actor
WHERE actor_id = 45
LIMIT 5;

# film_category table
SELECT *
FROM dvd_rentals.film_category
LIMIT 10;

# inventory table
SELECT *
FROM dvd_rentals.inventory
LIMIT 10;
-- Total number of inventories
SELECT COUNT(*)
FROM dvd_rentals.inventory;
-- Inventory records for one film_id
SELECT * FROM dvd_rentals.inventory
WHERE film_id = 10;

# rental table
SELECT *
FROM dvd_rentals.rental
LIMIT 10;
-- Total rentals
SELECT COUNT(*)
FROM dvd_rentals.rental;
-- records for one customer
SELECT *
FROM dvd_rentals.rental
WHERE customer_id = 5
LIMIT 5;

# Joining tables
DROP TABLE IF EXISTS complete_joint_dataset;
CREATE TEMPORARY TABLE complete_joint_dataset AS (
SELECT
  rental.customer_id,
  inventory.film_id,
  film.title,
  category.name AS category_name,
  rental.rental_date
FROM dvd_rentals.rental
INNER JOIN dvd_rentals.inventory
  ON rental.inventory_id = inventory.inventory_id
INNER JOIN dvd_rentals.film
  ON inventory.film_id = film.film_id
INNER JOIN dvd_rentals.film_category
  ON film.film_id = film_category.film_id
INNER JOIN dvd_rentals.category
  ON film_category.category_id = category.category_id
);

-- Display sample outputs from the above table
SELECT *
FROM complete_joint_dataset
LIMIT 5;
 
-- Category counts
DROP TABLE IF EXISTS category_counts;
CREATE TEMPORARY TABLE category_counts AS (
SELECT
  customer_id,
  category_name,
  COUNT(*) AS rental_count,
  MAX(rental_date) AS latest_rental_date
FROM complete_joint_dataset
GROUP BY 
  customer_id,
  category_name
);

-- Display sample outputs from the above table
SELECT *
FROM category_counts
WHERE customer_id = 1
ORDER BY
  rental_count DESC,
  latest_rental_date DESC;

-- Total counts
DROP TABLE IF EXISTS total_counts;
CREATE TEMPORARY TABLE total_counts AS(
SELECT
  customer_id,
  SUM(rental_count) AS total_count
FROM category_counts
GROUP BY customer_id
);

-- Display sample outputs from the above table
SELECT *
FROM total_counts
ORDER BY customer_id
LIMIT 5;

-- Top categories
DROP TABLE IF EXISTS top_categories;
CREATE TEMPORARY TABLE top_categories AS (
WITH ranked_cte AS (
  SELECT
    customer_id,
    category_name,
    rental_count,
    DENSE_RANK() OVER (
      PARTITION BY customer_id
      ORDER BY
        rental_count DESC,
        latest_rental_date DESC,
        category_name
    ) AS category_rank
  FROM category_counts
)

SELECT *
FROM ranked_cte
WHERE category_rank <= 2
);

-- Display sample outputs from the above table
SELECT *
FROM top_categories
LIMIT 5;

-- Average category counts
DROP TABLE IF EXISTS average_category_count;
CREATE TEMPORARY TABLE average_category_count AS (
SELECT
  category_name,
  FLOOR(AVG(rental_count)) AS category_count
FROM category_counts
GROUP BY category_name
);

-- Display sample outputs from the above table
SELECT *
FROM average_category_count
ORDER BY category_name;

-- CATEGORY RECOMMENDATIONS
-- Film counts
DROP TABLE IF EXISTS film_counts;
CREATE TEMPORARY TABLE film_counts AS (
SELECT DISTINCT
  film_id,
  title,
  category_name,
  COUNT(*) OVER (
    PARTITION BY film_id
  ) AS rental_count
FROM complete_joint_dataset
);

SELECT *
FROM film_counts
ORDER BY rental_count DESC
LIMIT 5;

-- Actor joint dataset
DROP TABLE IF EXISTS actor_joint_dataset;
CREATE TEMPORARY TABLE actor_joint_dataset AS (
SELECT 
  rental.customer_id,
  rental.rental_id,
  rental.rental_date,
  film.film_id,
  film.title,
  actor.actor_id,
  actor.first_name,
  actor.last_name
FROM dvd_rentals.rental
INNER JOIN dvd_rentals.inventory
  ON rental.inventory_id = inventory.inventory_id
INNER JOIN dvd_rentals.film
  ON inventory.film_id = film.film_id
INNER JOIN dvd_rentals.film_actor
  ON film.film_id = film_actor.film_id
INNER JOIN dvd_rentals.actor
  ON film_actor.actor_id = actor.actor_id
);

SELECT *
FROM actor_joint_dataset
LIMIT 5;

-- Actor Recommendations
-- Actor film counts
DROP TABLE IF EXISTS actor_film_counts;
CREATE TEMPORARY TABLE actor_film_counts AS (
WITH film_counts AS (
SELECT
  film_id,
  COUNT(DISTINCT rental_id) AS rental_count
FROM actor_joint_dataset
GROUP BY film_id
)

SELECT DISTINCT
  actor_joint_dataset.film_id,
  actor_joint_dataset.actor_id,
  actor_joint_dataset.title,
  film_counts.rental_count
FROM actor_joint_dataset
LEFT JOIN film_counts
  ON actor_joint_dataset.film_id = film_counts.film_id
);

-- Display sample row outputs from above table
SELECT *
FROM actor_film_counts
LIMIT 5;
