/*
Goal: Summarize net paid and profit by shipping address and time‑of‑day for a realistic, heavily‑filtered sales slice. The query demonstrates:
- TABLESAMPLE BERNOULLI on catalog_sales
- Multiple selective predicates with realistic literals
- A scalar subquery comparison
- A CTE hierarchy
- UNION (distinct) to de‑duplicate rows
- CASE WHEN logic in the projection
- GROUPING SETS for flexible aggregation across address and AM/PM shift
- Final ordering by total net paid
*/
WITH filtered_sales AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_addr_sk,
        cs_ship_cdemo_sk,
        cs_coupon_amt,
        cs_quantity,
        cs_net_paid,
        cs_net_profit
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)    -- sample 10% of rows
    WHERE cs_ship_addr_sk IN (5398171, 1419986, 1373579)
      AND cs_ship_cdemo_sk = 27132
      AND cs_coupon_amt BETWEEN 500 AND 6000
      AND cs_quantity >= 2
      AND cs_net_paid > 0
      AND cs_ship_addr_sk > (SELECT MIN(cs_ship_addr_sk) FROM catalog_sales) -- scalar subquery
),

time_filtered AS (
    SELECT
        t_time_sk,
        t_time,
        t_minute,
        t_am_pm
    FROM time_dim
    WHERE t_minute IN (0, 3, 8, 9, 10)
      AND t_time BETWEEN 0 AND 18
),

union_sales AS (
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_addr_sk,
        cs_ship_cdemo_sk,
        cs_coupon_amt,
        cs_quantity,
        cs_net_paid,
        cs_net_profit
    FROM filtered_sales
    UNION   -- DISTINCT union to deduplicate
    SELECT
        cs_sold_date_sk,
        cs_sold_time_sk,
        cs_ship_addr_sk,
        cs_ship_cdemo_sk,
        cs_coupon_amt,
        cs_quantity,
        cs_net_paid,
        cs_net_profit
    FROM filtered_sales
    WHERE cs_coupon_amt < 1000
)
SELECT
    us.cs_ship_addr_sk,
    tf.t_am_pm,
    SUM(us.cs_net_paid)               AS total_net_paid,
    AVG(us.cs_net_profit)             AS avg_net_profit,
    COUNT(*)                          AS transaction_cnt,
    MIN(us.cs_coupon_amt)             AS min_coupon_amt,
    MAX(us.cs_coupon_amt)             AS max_coupon_amt,
    CASE
        WHEN SUM(us.cs_coupon_amt) > 5000 THEN 'HIGH_TOTAL'
        ELSE 'LOW_TOTAL'
    END                               AS coupon_total_level
FROM union_sales us
JOIN time_filtered tf
    ON us.cs_sold_time_sk = tf.t_time_sk
GROUP BY GROUPING SETS (
    (us.cs_ship_addr_sk, tf.t_am_pm),
    (us.cs_ship_addr_sk),
    (tf.t_am_pm),
    ()
)
ORDER BY total_net_paid DESC
LIMIT 100
