WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_sold_date_sk BETWEEN 2451545 AND 2451910
),
customer_purchases AS (
    SELECT c.c_customer_id,
           i.i_class,
           SUM(ss.ss_quantity) AS total_qty,
           SUM(ss.ss_net_paid) AS total_paid
    FROM sampled_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY GROUPING SETS ((c.c_customer_id, i.i_class), (c.c_customer_id))
),
store_returns_filtered AS (
    SELECT DISTINCT c.c_customer_id
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE sr.sr_return_amt > 100
),
promo_items AS (
    SELECT p.p_promo_sk, i.i_item_sk
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
),
lateral_promo AS (
    SELECT cp.c_customer_id,
           cp.i_class,
           cp.total_qty,
           cp.total_paid,
           pi.p_promo_sk
    FROM customer_purchases cp
    LEFT JOIN LATERAL (
        SELECT p.p_promo_sk
        FROM promo_items p
        WHERE p.i_item_sk = (
            SELECT i_item_sk
            FROM item
            WHERE i_class = cp.i_class
            LIMIT 1
        )
        LIMIT 1
    ) pi ON TRUE
),
high_spenders AS (
    SELECT c_customer_id
    FROM lateral_promo
    WHERE total_paid > 1000
),
sports_customers AS (
    SELECT c_customer_id
    FROM lateral_promo
    WHERE i_class = 'sports-apparel'
)
SELECT *
FROM (
    SELECT c_customer_id FROM high_spenders
    INTERSECT
    SELECT c_customer_id FROM sports_customers
) AS intersect_set
EXCEPT
SELECT c_customer_id FROM store_returns_filtered
ORDER BY c_customer_id
