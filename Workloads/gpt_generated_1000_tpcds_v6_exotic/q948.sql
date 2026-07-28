WITH sales_data AS (
  SELECT
    i.i_item_id,
    d.d_year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
    cc.cc_name AS call_center_name
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
  WHERE d.d_year = 1998
    AND i.i_brand = 'Brand#12'
    AND cd.cd_gender = 'M'
    AND t.t_hour BETWEEN 8 AND 12
    AND ss.ss_quantity > 1
  GROUP BY i.i_item_id, d.d_year, cc.cc_name
),

returns_data AS (
  SELECT
    i.i_item_id,
    d.d_year,
    SUM(wr.wr_return_amt) AS total_return,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    ws.web_name AS web_site_name
  FROM web_returns wr
  JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
  JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
  JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 1998
    AND i.i_brand = 'Brand#12'
    AND cd.cd_marital_status = 'M'
    AND t.t_hour BETWEEN 8 AND 12
    AND wr.wr_return_quantity > 0
  GROUP BY i.i_item_id, d.d_year, ws.web_name
)

SELECT
  item_id,
  SUM(total_sales) AS sum_sales,
  SUM(total_return) AS sum_return,
  COUNT(DISTINCT call_center_name) AS distinct_call_centers,
  COUNT(DISTINCT web_site_name) AS distinct_web_sites,
  (SUM(total_sales) - SUM(total_return)) / NULLIF(SUM(total_sales), 0) AS profit_margin
FROM (
  SELECT
    i_item_id AS item_id,
    total_sales,
    NULL AS total_return,
    call_center_name,
    NULL AS web_site_name
  FROM sales_data
  UNION ALL
  SELECT
    i_item_id AS item_id,
    NULL AS total_sales,
    total_return,
    NULL AS call_center_name,
    web_site_name
  FROM returns_data
) combined
GROUP BY item_id
HAVING SUM(total_sales) > 10000
ORDER BY profit_margin DESC
LIMIT 100
