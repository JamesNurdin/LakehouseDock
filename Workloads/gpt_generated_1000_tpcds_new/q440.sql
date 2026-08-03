WITH
  /* Aggregate store sales per customer and year */
  sales_agg AS (
    SELECT
      ss.ss_customer_sk,
      d.d_year,
      SUM(ss.ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE d.d_holiday = 'N'
      AND d.d_year = 2001
      AND t.t_shift = 'first'
    GROUP BY ss.ss_customer_sk, d.d_year
  ),

  /* Customers that appear in both store sales and web returns */
  intersect_customers AS (
    SELECT ss_customer_sk FROM store_sales
    INTERSECT
    SELECT wr_refunded_customer_sk FROM web_returns
  ),

  /* Sampled inventory joined to date_dim with a full outer join */
  inv_date AS (
    SELECT
      inv.inv_date_sk,
      inv.inv_quantity_on_hand,
      d.d_date,
      d.d_holiday,
      d.d_year
    FROM (SELECT * FROM inventory TABLESAMPLE BERNOULLI (10)) inv
    FULL OUTER JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE (inv.inv_quantity_on_hand > 0 OR inv.inv_quantity_on_hand IS NULL)
      AND d.d_holiday = 'N'
  )

SELECT
  c.c_customer_id,
  cd.cd_gender,
  cp.cp_catalog_page_number,
  d_main.d_date,
  t.t_time,
  invd.inv_quantity_on_hand,
  sa.total_net_paid,
  sa.sales_cnt,
  CASE WHEN sa.total_net_paid > 1000 THEN 'High' ELSE 'Low' END AS revenue_category,
  ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY sa.total_net_paid DESC) AS rn
FROM intersect_customers ic
JOIN customer c ON ic.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN sales_agg sa ON c.c_customer_sk = sa.ss_customer_sk
JOIN inv_date invd ON YEAR(invd.d_date) = sa.d_year
JOIN catalog_page cp ON cp.cp_start_date_sk = invd.inv_date_sk
JOIN date_dim d_main ON cp.cp_end_date_sk = d_main.d_date_sk
JOIN time_dim t ON t.t_time_sk = (SELECT MIN(t2.t_time_sk) FROM time_dim t2 WHERE t2.t_shift = 'first')
LEFT JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk AND d_sr.d_holiday = 'N'
LEFT JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk AND d_wr.d_holiday = 'N'
WHERE c.c_preferred_cust_flag = 'Y'
  AND cp.cp_type = 'catalog'
  AND sr.sr_return_quantity > 0
  AND wr.wr_return_quantity > 0
  AND invd.inv_quantity_on_hand IS NOT NULL
ORDER BY revenue_category ASC, rn ASC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
