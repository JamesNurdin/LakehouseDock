/*
  Goal: Analyze store performance by customer demographic segment, showing the top stores with profit categories, average discount, and a rank per store. The query joins store_sales, customer_demographics and store, applies multiple selective filters, uses a CTE for pre‑aggregation, includes scalar and EXISTS subqueries, a CASE expression, and a window function.
*/
WITH sales_agg AS (
    SELECT
        ss_store_sk,
        ss_cdemo_sk,
        SUM(ss_net_paid)               AS total_net_paid,
        SUM(ss_ext_discount_amt)       AS total_discount,
        COUNT(*)                       AS sales_cnt
    FROM store_sales
    WHERE ss_list_price > 20.00               -- predicate 1
      AND ss_quantity > 0                     -- predicate 2
    GROUP BY ss_store_sk, ss_cdemo_sk
),
joined AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_rec_end_date,
        s.s_market_desc,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_employed_count,
        sa.total_net_paid,
        sa.total_discount,
        sa.sales_cnt,
        (
            SELECT MAX(ss3.ss_ext_list_price)
            FROM store_sales ss3
            WHERE ss3.ss_store_sk = s.s_store_sk
        ) AS max_ext_list_price               -- scalar subquery
    FROM sales_agg sa
    JOIN store s ON sa.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON sa.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_rec_end_date = DATE '2000-03-12'                     -- predicate 3
      AND s.s_market_desc LIKE '%bars%'                           -- predicate 4
      AND cd.cd_dep_employed_count >= 2
      AND EXISTS (
            SELECT 1
            FROM store_sales ss4
            WHERE ss4.ss_store_sk = s.s_store_sk
              AND ss4.ss_ext_tax > 0
        )                                                          -- EXISTS subquery
),
aggregated AS (
    SELECT
        j.s_store_id,
        j.s_store_name,
        j.cd_gender,
        j.cd_marital_status,
        SUM(j.total_net_paid)   AS sum_net_paid,
        AVG(j.total_discount)   AS avg_discount,
        COUNT(*)                AS num_segments,
        CASE
            WHEN SUM(j.total_net_paid) >= 50000 THEN 'High'
            WHEN SUM(j.total_net_paid) >= 20000 THEN 'Medium'
            ELSE 'Low'
        END                     AS profit_category,
        j.max_ext_list_price
    FROM joined j
    GROUP BY
        j.s_store_id,
        j.s_store_name,
        j.cd_gender,
        j.cd_marital_status,
        j.max_ext_list_price
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.cd_gender,
    a.cd_marital_status,
    a.sum_net_paid,
    a.avg_discount,
    a.num_segments,
    a.profit_category,
    a.max_ext_list_price,
    ROW_NUMBER() OVER (PARTITION BY a.s_store_id ORDER BY a.sum_net_paid DESC) AS rank_within_store   -- window function
FROM aggregated a
ORDER BY a.sum_net_paid DESC
LIMIT 100
