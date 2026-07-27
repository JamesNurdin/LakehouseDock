/*
  goal: Rank customers by their combined store and web sales for recent fiscal years, segmented by income band, applying multiple filters and using a window function with a subquery.
*/
WITH ws_filtered AS (
    SELECT
        ws_bill_customer_sk,
        ws_sold_date_sk,
        ws_net_paid
    FROM web_sales
    WHERE ws_net_paid > 1000
)
SELECT
    c.c_customer_id,
    d.d_year,
    ib.ib_upper_bound,
    SUM(ss.ss_ext_sales_price)                         AS store_sales_total,
    SUM(ws_filtered.ws_net_paid)                        AS web_sales_total,
    RANK() OVER (PARTITION BY d.d_year ORDER BY (SUM(ss.ss_ext_sales_price) + SUM(ws_filtered.ws_net_paid)) DESC) AS sales_rank,
    CASE
        WHEN ib.ib_upper_bound >= 150000 THEN 'High Income'
        ELSE 'Mid/Low Income'
    END                                                AS income_category
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN ws_filtered
    ON ws_filtered.ws_bill_customer_sk = c.c_customer_sk
   AND ws_filtered.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1910 AND 1915
  AND c.c_birth_year BETWEEN 1950 AND 1970
  AND hd.hd_dep_count <= 2
  AND ib.ib_upper_bound >= 100000
  AND ss.ss_quantity > 1
GROUP BY
    c.c_customer_id,
    d.d_year,
    ib.ib_upper_bound,
    CASE
        WHEN ib.ib_upper_bound >= 150000 THEN 'High Income'
        ELSE 'Mid/Low Income'
    END
ORDER BY sales_rank
LIMIT 100
