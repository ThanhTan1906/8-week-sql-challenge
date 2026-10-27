-- =============================================
-- Week 1: Danny's Diner
-- 8 Week SQL Challenge
-- =============================================

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS Total_spent
FROM sales AS s
INNER JOIN menu AS m
      ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY Total_spent DESC;


-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT(order_date)) AS Visit_days
FROM sales
GROUP BY customer_id
ORDER BY Visit_days DESC;

-- 3. What was the first item from the menu purchased by each customer?
WITH first_purchased AS(
  SELECT s.customer_id, s.order_date, m.product_name,
  DENSE_RANK() OVER (
    PARTITION BY customer_id
    ORDER BY order_date ASC
) AS purchase_rank
  FROM sales as s
  INNER JOIN menu as m ON s.product_id = m.product_id
  )
 SELECT DISTINCT customer_id, product_name
 FROM first_purchased
 WHERE purchase_rank = 1
 ORDER BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.order_date) AS purchase_count
FROM menu m 
INNER JOIN sales as s ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY purchase_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH purchase_count AS (
  SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count
FROM sales AS s 
INNER JOIN menu as m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
  )
, rank_items AS(
  SELECT customer_id, product_name, purchase_count,
    DENSE_RANK() OVER (
    PARTITION BY customer_id
    ORDER BY purchase_count DESC
    ) AS purchase_rank
FROM purchase_count
  )
SELECT customer_id,
    product_name,
    purchase_count
FROM rank_items
WHERE purchase_rank = 1;

 


-- 6. Which item was purchased first by the customer after they became a member?
WITH member_purchases AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name
    FROM sales AS s
    INNER JOIN menu AS m
        ON s.product_id = m.product_id
    INNER JOIN members AS me
        ON s.customer_id = me.customer_id
    WHERE s.order_date >= me.join_date
),
ranked_purchases AS (
    SELECT
        customer_id,
        product_name,
        order_date,
        DENSE_RANK() OVER (
            PARTITION BY customer_id
            ORDER BY order_date ASC
        ) AS purchase_rank
    FROM member_purchases
)

SELECT
    customer_id,
    product_name
FROM ranked_purchases
WHERE purchase_rank = 1
ORDER BY customer_id, product_name;


-- 7. Which item was purchased just before the customer became a member?
WITH member_purchases AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name
    FROM sales AS s
    INNER JOIN menu AS m
        ON s.product_id = m.product_id
    INNER JOIN members AS me
        ON s.customer_id = me.customer_id
    WHERE s.order_date < me.join_date
),
ranked_purchases AS (
    SELECT
        customer_id,
        product_name,
        order_date,
        DENSE_RANK() OVER (
            PARTITION BY customer_id
            ORDER BY order_date DESC
        ) AS purchase_rank
    FROM member_purchases
)

SELECT
    customer_id,
    product_name
FROM ranked_purchases
WHERE purchase_rank = 1
ORDER BY customer_id, product_name;



-- 8. What is the total items and amount spent for each member before they became a member?
SELECT
        s.customer_id,
        COUNT(*) AS total_items,
        SUM(m.price) AS total_amount
        
    FROM sales AS s
    INNER JOIN menu AS m
        ON s.product_id = m.product_id
    INNER JOIN members AS me
        ON s.customer_id = me.customer_id
    WHERE s.order_date < me.join_date
    GROUP BY s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT
    s.customer_id,
        SUM(
    CASE
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
    END
) AS total_points
        
FROM sales AS s
INNER JOIN menu AS m
        ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_points DESC;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
    s.customer_id,
        SUM(
    CASE
        WHEN s.order_date BETWEEN me.join_date
                 AND me.join_date + INTERVAL '6 days' THEN m.price * 20
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
    END
) AS total_points
        
FROM sales AS s
INNER JOIN menu AS m
        ON s.product_id = m.product_id
INNER JOIN members AS me
    ON s.customer_id = me.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY total_points DESC;



-- Bonus 1: Join All The Things

SELECT
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN s.order_date >= me.join_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM sales AS s
INNER JOIN menu AS m
    ON s.product_id = m.product_id
LEFT JOIN members AS me
    ON s.customer_id = me.customer_id
ORDER BY
    s.customer_id,
    s.order_date,
    m.product_name;


-- Bonus 2: Rank All The Things

WITH member_status AS (
    SELECT
        s.customer_id,
        s.order_date,
        m.product_name,
        m.price,
        CASE
            WHEN s.order_date >= me.join_date THEN 'Y'
            ELSE 'N'
        END AS member
    FROM sales AS s
    INNER JOIN menu AS m
        ON s.product_id = m.product_id
    LEFT JOIN members AS me
        ON s.customer_id = me.customer_id
)

SELECT
    customer_id,
    order_date,
    product_name,
    price,
    member,
    CASE
        WHEN member = 'Y' THEN
            DENSE_RANK() OVER (
                PARTITION BY customer_id, member
                ORDER BY order_date
            )
        ELSE NULL
    END AS ranking
FROM member_status
ORDER BY
    customer_id,
    order_date,
    product_name;