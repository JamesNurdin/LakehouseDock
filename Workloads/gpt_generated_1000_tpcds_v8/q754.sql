WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)   -- sample 10 % of rows
    WHERE ss.ss_net_profit > 0
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    CONCAT(MIN(s.s_city), ', ', MIN(s.s_state)) AS store_location,
    REGEXP_EXTRACT(MIN(s.s_suite_number), '(\\d+)') AS suite_number_numeric,
    SUM(fs.ss_ext_sales_price) AS total_sales,
    SUM(fs.ss_net_profit) AS total_profit,
    AVG(p.p_cost) AS avg_promo_cost
FROM filtered_sales fs
JOIN store s ON fs.ss_store_sk = s.s_store_sk
JOIN promotion p ON fs.ss_promo_sk = p.p_promo_sk
JOIN customer c ON fs.ss_customer_sk = c.c_customer_sk
WHERE
    REGEXP_LIKE(s.s_suite_number, '^Suite [0-9]+')                 -- suite numbers that are numeric
    AND c.c_email_address LIKE '%@example.com'                     -- only customers with example.com emails
    AND fs.ss_store_sk NOT IN (
        SELECT sr.sr_store_sk
        FROM store_returns sr
        WHERE sr.sr_net_loss > 0
    )
GROUP BY GROUPING SETS (
    (s.s_store_name, p.p_promo_name),   -- store + promo level
    (s.s_store_name),                   -- store only level
    ()                                   -- grand total
)
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
