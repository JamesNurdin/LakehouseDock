WITH missing_items AS (
    SELECT i.inv_item_sk
    FROM inventory i
    EXCEPT
    SELECT ss.ss_item_sk
    FROM store_sales ss
),
max_year AS (
    SELECT MAX(d2.d_year) AS yr
    FROM date_dim d2
)
SELECT
    ROW_NUMBER() OVER (ORDER BY d_sold.d_year, s.s_store_name) AS row_num,
    s.s_store_name,
    d_sold.d_year,
    w.w_warehouse_name,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns,
    COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
    COUNT(DISTINCT wr.wr_returning_customer_sk) AS distinct_return_customers,
    (SELECT yr FROM max_year) AS max_year,
    (SELECT COUNT(*) FROM missing_items) AS missing_item_count,
    v.flag
FROM store_sales ss
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN time_dim td
  ON ss.ss_sold_time_sk = td.t_time_sk
JOIN household_demographics hd_sales
  ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN catalog_page cp
  ON cp.cp_start_date_sk = d_sold.d_date_sk
JOIN inventory i
  ON i.inv_date_sk = d_sold.d_date_sk
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_sold.d_date_sk
 AND wr.wr_returned_time_sk = td.t_time_sk
JOIN reason r
  ON wr.wr_reason_sk = r.r_reason_sk
-- Re‑use DATE_DIM under a different alias for the store closed date
JOIN date_dim d_return
  ON s.s_closed_date_sk = d_return.d_date_sk
CROSS JOIN (VALUES (1), (2)) AS v(flag)
WHERE d_sold.d_year BETWEEN 1995 AND 1997
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_name,
    d_sold.d_year,
    w.w_warehouse_name,
    v.flag,
    d_sold.d_year
ORDER BY total_sales DESC
LIMIT 100
