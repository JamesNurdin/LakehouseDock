WITH base AS (
   SELECT
     ss.ss_ext_sales_price,
     sr.sr_refunded_cash,
     s.s_store_id,
     d_sales.d_year,
     cd.cd_credit_rating,
     c.c_birth_year,
     p.p_cost,
     t.t_hour
   FROM store_sales ss
   JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                               AND sr.sr_item_sk = ss.ss_item_sk
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                           AND wp.wp_creation_date_sk = c.c_first_sales_date_sk
   WHERE c.c_birth_year BETWEEN 1960 AND 1990
     AND cd.cd_credit_rating = 'Good'
     AND d_sales.d_year = 2001
     AND p.p_cost > 100.00
     AND t.t_hour BETWEEN 9 AND 17
),
agg AS (
   SELECT
     s_store_id,
     d_year,
     SUM(ss_ext_sales_price)                         AS total_sales,
     SUM(COALESCE(sr_refunded_cash, 0))               AS total_refunds
   FROM base
   GROUP BY GROUPING SETS (
     (s_store_id, d_year),
     (s_store_id),
     (d_year),
     ()
   )
),
ranked AS (
   SELECT
     s_store_id,
     d_year,
     total_sales,
     total_refunds,
     CASE WHEN total_sales > 100000 THEN 'High' ELSE 'Medium' END AS sales_category,
     ROW_NUMBER() OVER (ORDER BY total_sales DESC)                           AS rn,
     LAG(total_sales) OVER (PARTITION BY s_store_id ORDER BY d_year)         AS prev_year_sales
   FROM agg
)
SELECT *
FROM (
   SELECT s_store_id, d_year, total_sales, total_refunds, sales_category, rn, prev_year_sales
   FROM ranked
) 
EXCEPT
SELECT s_store_id, d_year, total_sales, total_refunds, sales_category, rn, prev_year_sales
FROM ranked
WHERE total_sales < 10000
ORDER BY total_sales DESC
LIMIT 100
