WITH all_sales AS (
    SELECT s.s_store_id AS store_id,
           d.d_year AS year,
           SUM(ss.ss_ext_sales_price) AS sales_amount,
           'ALL_SALES' AS sales_type
    FROM tpcds.store_sales AS ss
    JOIN tpcds.date_dim AS d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store AS s
      ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_id, d.d_year
),
promo_sales AS (
    SELECT s.s_store_id AS store_id,
           d.d_year AS year,
           SUM(ss.ss_ext_sales_price) AS sales_amount,
           'PROMO_SALES' AS sales_type
    FROM tpcds.store_sales AS ss
    JOIN tpcds.date_dim AS d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store AS s
      ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion AS p
      ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
    GROUP BY s.s_store_id, d.d_year
)
SELECT store_id,
       year,
       sales_amount,
       sales_type
FROM all_sales
UNION ALL
SELECT store_id,
       year,
       sales_amount,
       sales_type
FROM promo_sales
ORDER BY store_id,
         year,
         sales_type
