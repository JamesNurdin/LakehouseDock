WITH
  agg_sales AS (
    SELECT
      ss_store_sk,
      ss_sold_date_sk,
      SUM(ss_net_paid) AS total_net_paid,
      COUNT(*) AS sales_cnt
    FROM tpcds.store_sales
    WHERE ss_quantity > 1
    GROUP BY ss_store_sk, ss_sold_date_sk
  ),
  agg_cat_ret AS (
    SELECT
      cr_call_center_sk,
      cr_returned_date_sk,
      SUM(cr_return_amount) AS total_return_amount,
      COUNT(*) AS ret_cnt
    FROM tpcds.catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_call_center_sk, cr_returned_date_sk
  ),
  sample_inventory AS (
    SELECT *
    FROM tpcds.inventory TABLESAMPLE BERNOULLI (10)
  ),
  years_common AS (
    SELECT d_year
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales s ON s.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    INTERSECT
    SELECT d_year
    FROM tpcds.date_dim d
    JOIN tpcds.web_returns w ON w.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
  )
SELECT
  d_sales.d_year,
  s.s_store_name,
  r.r_reason_desc,
  CASE
    WHEN SUM(COALESCE(agg_sales.total_net_paid, 0)) - SUM(COALESCE(agg_cat_ret.total_return_amount, 0)) > 10000 THEN 'HIGH'
    ELSE 'LOW'
  END AS profit_category,
  SUM(COALESCE(agg_sales.total_net_paid, 0)) AS total_store_sales,
  SUM(COALESCE(agg_cat_ret.total_return_amount, 0)) AS total_catalog_returns,
  COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
  SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
  MIN(t_sr.t_hour) AS earliest_return_hour,
  MAX(t_sr.t_hour) AS latest_return_hour,
  MAX(ws.web_name) AS web_site_name
FROM agg_sales
FULL OUTER JOIN agg_cat_ret
  ON agg_sales.ss_sold_date_sk = agg_cat_ret.cr_returned_date_sk
JOIN tpcds.store s
  ON agg_sales.ss_store_sk = s.s_store_sk
LEFT JOIN tpcds.call_center cc
  ON agg_cat_ret.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
     AND sr.sr_returned_date_sk = agg_sales.ss_sold_date_sk
LEFT JOIN tpcds.reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN tpcds.customer_address ca
  ON sr.sr_addr_sk = ca.ca_address_sk
LEFT JOIN tpcds.customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
LEFT JOIN tpcds.household_demographics hd
  ON sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN tpcds.web_returns wr
  ON wr.wr_returned_date_sk = agg_sales.ss_sold_date_sk
LEFT JOIN tpcds.web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN tpcds.time_dim t_sr
  ON sr.sr_return_time_sk = t_sr.t_time_sk
LEFT JOIN sample_inventory inv
  ON inv.inv_date_sk = agg_sales.ss_sold_date_sk
LEFT JOIN tpcds.date_dim d_sales
  ON agg_sales.ss_sold_date_sk = d_sales.d_date_sk
LEFT JOIN years_common yc
  ON d_sales.d_year = yc.d_year
LEFT JOIN tpcds.web_site ws
  ON ws.web_open_date_sk = d_sales.d_date_sk
WHERE
  d_sales.d_year = 2000
  AND s.s_state = 'CA'
  AND cc.cc_market_manager = 'John Doe'
  AND ca.ca_state = 'TX'
  AND r.r_reason_id = '01'
GROUP BY CUBE (d_sales.d_year, s.s_store_name, r.r_reason_desc)
ORDER BY total_store_sales DESC
LIMIT 100
