WITH joined_data AS (
  SELECT
    d_ss.d_year AS year,
    s.s_store_name,
    cp.cp_department,
    r.r_reason_desc,
    ss.ss_ext_sales_price AS store_sales_amount,
    ws.ws_ext_sales_price AS web_sales_amount,
    cr.cr_return_amount,
    inv.inv_quantity_on_hand
  FROM store_sales ss
  JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
  JOIN time_dim t_ss
    ON ss.ss_sold_time_sk = t_ss.t_time_sk
  JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN web_sales ws
    ON ss.ss_item_sk = ws.ws_item_sk
   AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
  LEFT JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
  LEFT JOIN catalog_returns cr
    ON ss.ss_item_sk = cr.cr_item_sk
   AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
  LEFT JOIN date_dim d_cr
    ON cr.cr_returned_date_sk = d_cr.d_date_sk
  LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN inventory inv
    ON ss.ss_item_sk = inv.inv_item_sk
   AND d_ss.d_date_sk = inv.inv_date_sk
),
aggregated AS (
  SELECT
    year,
    s_store_name,
    cp_department,
    r_reason_desc,
    SUM(store_sales_amount) AS total_store_sales,
    SUM(web_sales_amount) AS total_web_sales,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand
  FROM joined_data
  GROUP BY GROUPING SETS (
    (year, s_store_name, cp_department, r_reason_desc),
    (year, s_store_name, cp_department),
    (year, s_store_name),
    (year)
  )
)
SELECT
  year,
  s_store_name,
  cp_department,
  r_reason_desc,
  total_store_sales,
  total_web_sales,
  total_return_amount,
  total_inventory_on_hand,
  SUM(total_store_sales) OVER (PARTITION BY year ORDER BY s_store_name
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_store_sales_by_store
FROM aggregated
ORDER BY year DESC, s_store_name ASC, cp_department ASC
LIMIT 100
