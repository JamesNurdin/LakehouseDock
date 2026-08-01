WITH sampled_sales AS (
    SELECT *
    FROM tpcds.catalog_sales TABLESAMPLE BERNOULLI (10)
),
sub1 AS (
    SELECT
        cs.cs_warehouse_sk AS cs_warehouse_sk,
        d.d_year AS d_year,
        w.w_warehouse_name AS w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM sampled_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_warehouse_sq_ft > 500000
      AND d.d_fy_quarter_seq = 14
      AND EXISTS (
          SELECT 1
          FROM tpcds.catalog_sales cs2
          WHERE cs2.cs_warehouse_sk = cs.cs_warehouse_sk
            AND cs2.cs_net_paid_inc_ship_tax > 10000
            AND cs2.cs_sold_date_sk = cs.cs_sold_date_sk
      )
    GROUP BY cs.cs_warehouse_sk, d.d_year, w.w_warehouse_name
),
sub2 AS (
    SELECT
        cs.cs_warehouse_sk AS cs_warehouse_sk,
        d.d_year AS d_year,
        w.w_warehouse_name AS w_warehouse_name,
        SUM(cs.cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM sampled_sales cs
    JOIN tpcds.date_dim d
        ON cs.cs_ship_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_street_name LIKE '%Laurel%'
      AND d.d_following_holiday = 'Y'
    GROUP BY cs.cs_warehouse_sk, d.d_year, w.w_warehouse_name
)
SELECT
    i.w_warehouse_name,
    i.d_year,
    i.total_profit,
    i.profit_rank,
    AVG(i.total_profit) OVER (PARTITION BY i.d_year) AS avg_profit_year
FROM (
    SELECT cs_warehouse_sk, d_year, w_warehouse_name, total_profit, profit_rank
    FROM sub1
    INTERSECT
    SELECT cs_warehouse_sk, d_year, w_warehouse_name, total_profit, profit_rank
    FROM sub2
) i
JOIN tpcds.warehouse w
    ON i.cs_warehouse_sk = w.w_warehouse_sk
ORDER BY i.total_profit DESC
OFFSET 10
LIMIT 100
