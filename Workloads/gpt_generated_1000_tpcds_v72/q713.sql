WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        i.i_product_name,
        s.s_state,
        s.s_city
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE regexp_like(i.i_product_name, '[A-Za-z]+[0-9]+')
      AND s.s_state LIKE 'A%'
)
SELECT
    c.c_customer_id,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    i.i_product_name,
    REGEXP_EXTRACT(i.i_product_name, '([0-9]+)', 1) AS product_number,
    SUM(fs.ss_net_paid) AS total_spent,
    SUM(fs.ss_net_profit) AS total_profit
FROM filtered_sales fs
JOIN customer c ON fs.ss_customer_sk = c.c_customer_sk
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN item i ON fs.ss_item_sk = i.i_item_sk
WHERE fs.ss_net_profit > (
        SELECT AVG(ss2.ss_net_profit)
        FROM store_sales ss2
    )
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_discount_active = 'Y'
    )
GROUP BY
    c.c_customer_id,
    CONCAT(s.s_city, ', ', s.s_state),
    i.i_product_name,
    REGEXP_EXTRACT(i.i_product_name, '([0-9]+)', 1)
ORDER BY total_spent DESC
LIMIT 100
