WITH high_cost_sales AS (
    SELECT d.d_year AS sale_year,
           s.s_store_name AS store_name,
           p.p_promo_name AS promo_name,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_quantity) AS total_quantity,
           (
               SELECT AVG(ss2.ss_ext_discount_amt)
               FROM store_sales ss2
               WHERE ss2.ss_promo_sk = p.p_promo_sk
           ) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2000
      AND p.p_cost > 5000
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          JOIN date_dim d2 ON cp.cp_start_date_sk = d2.d_date_sk
          WHERE d2.d_date_sk = p.p_start_date_sk
            AND cp.cp_department = 'DEPARTMENT'
      )
    GROUP BY d.d_year, s.s_store_name, p.p_promo_name, p.p_promo_sk
),
low_cost_sales AS (
    SELECT d.d_year AS sale_year,
           s.s_store_name AS store_name,
           p.p_promo_name AS promo_name,
           SUM(ss.ss_ext_sales_price) AS total_sales,
           SUM(ss.ss_quantity) AS total_quantity,
           (
               SELECT AVG(ss2.ss_ext_discount_amt)
               FROM store_sales ss2
               WHERE ss2.ss_promo_sk = p.p_promo_sk
           ) AS avg_discount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_cost <= 5000
      AND s.s_number_employees > 100
    GROUP BY d.d_year, s.s_store_name, p.p_promo_name, p.p_promo_sk
)
SELECT sale_year,
       store_name,
       promo_name,
       total_sales,
       total_quantity,
       avg_discount
FROM high_cost_sales
UNION ALL
SELECT sale_year,
       store_name,
       promo_name,
       total_sales,
       total_quantity,
       avg_discount
FROM low_cost_sales
ORDER BY total_sales DESC
LIMIT 100
