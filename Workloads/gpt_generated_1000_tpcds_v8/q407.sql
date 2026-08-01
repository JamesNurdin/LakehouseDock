WITH sampled_sales AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
),
high_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_lower_bound >= 100000
),
low_income_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ib.ib_upper_bound <= 50000
),
target_customers AS (
    SELECT c_customer_sk FROM high_income_customers
    EXCEPT
    SELECT c_customer_sk FROM low_income_customers
)
SELECT
    i.i_brand,
    CASE
        WHEN ss.ss_net_profit > 0 THEN 'Profitable'
        WHEN ss.ss_net_profit = 0 THEN 'BreakEven'
        ELSE 'Loss'
    END AS profit_category,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    COUNT(DISTINCT ss.ss_item_sk) AS distinct_items,
    SUM(ss.ss_net_paid) AS total_revenue,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3,})') AS numeric_part_in_desc,
    hd.hd_buy_potential
FROM sampled_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    c.c_email_address LIKE '%@example.com'
    AND REGEXP_LIKE(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
    AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_customer_sk = ss.ss_customer_sk
          AND ss2.ss_net_profit > ss.ss_net_profit
    )
    AND ss.ss_customer_sk IN (SELECT c_customer_sk FROM target_customers)
GROUP BY
    i.i_brand,
    CASE
        WHEN ss.ss_net_profit > 0 THEN 'Profitable'
        WHEN ss.ss_net_profit = 0 THEN 'BreakEven'
        ELSE 'Loss'
    END,
    hd.hd_buy_potential,
    CONCAT(c.c_first_name, ' ', c.c_last_name),
    REGEXP_EXTRACT(i.i_item_desc, '(\\d{3,})')
ORDER BY total_revenue DESC
OFFSET 20 LIMIT 100
