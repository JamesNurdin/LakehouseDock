WITH
  store_sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      i.i_category,
      SUM(ss.ss_ext_sales_price) AS store_sales_amount,
      SUM(ss.ss_net_profit) AS store_profit
    FROM tpcds.store_sales ss
    JOIN tpcds.item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      i.i_category
  ),
  web_sales_agg AS (
    SELECT
      ws.ws_web_site_sk,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      i.i_category,
      SUM(ws.ws_ext_sales_price) AS web_sales_amount,
      SUM(ws.ws_net_profit) AS web_profit
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY
      ws.ws_web_site_sk,
      ws.ws_sold_date_sk,
      ws.ws_item_sk,
      i.i_category
  ),
  common_items AS (
    SELECT cr.cr_item_sk AS i_item_sk
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i ON cr.cr_item_sk = i.i_item_sk
    INTERSECT
    SELECT ws.ws_item_sk AS i_item_sk
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
  )
SELECT
  d.d_year,
  i.i_category,
  COUNT(DISTINCT s.s_store_sk) AS store_cnt,
  SUM(ssa.store_sales_amount) AS total_store_sales,
  SUM(wsa.web_sales_amount) AS total_web_sales,
  CASE
    WHEN SUM(ssa.store_sales_amount) > SUM(wsa.web_sales_amount) THEN 'Store Higher'
    ELSE 'Web Higher'
  END AS higher_channel,
  inv_qty.total_quantity_on_hand
FROM tpcds.date_dim d
JOIN store_sales_agg ssa ON ssa.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t ON t.t_time_sk = ssa.ss_sold_time_sk
JOIN tpcds.store s ON s.s_store_sk = ssa.ss_store_sk
JOIN tpcds.item i ON i.i_item_sk = ssa.ss_item_sk
JOIN web_sales_agg wsa ON wsa.ws_sold_date_sk = d.d_date_sk
                         AND wsa.ws_item_sk = i.i_item_sk
JOIN common_items ci ON ci.i_item_sk = i.i_item_sk
JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                              AND cr.cr_item_sk = i.i_item_sk
JOIN tpcds.reason r ON r.r_reason_sk = cr.cr_reason_sk
JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN tpcds.catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN tpcds.web_site wsit ON wsit.web_open_date_sk = d.d_date_sk
JOIN tpcds.warehouse w ON w.w_warehouse_sk = cr.cr_warehouse_sk
JOIN tpcds.customer_demographics cd ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
CROSS JOIN LATERAL (
  SELECT SUM(inv2.inv_quantity_on_hand) AS total_quantity_on_hand
  FROM tpcds.inventory inv2
  WHERE inv2.inv_date_sk = d.d_date_sk
    AND inv2.inv_item_sk = i.i_item_sk
) AS inv_qty
WHERE d.d_year = 2001
  AND i.i_category IN ('Books', 'Women')
  AND s.s_state = 'CA'
  AND cc.cc_country = 'United States'
  AND r.r_reason_desc LIKE '%damage%'
  AND wp.wp_type = 'JSON'
  AND cp.cp_department = 'Women'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY
  d.d_year,
  i.i_category,
  inv_qty.total_quantity_on_hand
ORDER BY d.d_year DESC, i.i_category
OFFSET 0 FETCH NEXT 100 ROWS ONLY
