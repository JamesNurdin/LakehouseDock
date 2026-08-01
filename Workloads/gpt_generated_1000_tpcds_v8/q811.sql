WITH
  filtered_time AS (
    SELECT t_time_sk,
           t_minute,
           t_sub_shift
    FROM   time_dim
    WHERE  t_sub_shift IN ('morning', 'afternoon')
  ),
  intersect_orders AS (
    SELECT cs_order_number
    FROM   catalog_sales cs
    WHERE  cs.cs_ext_sales_price > 500
    INTERSECT
    SELECT ws_order_number
    FROM   web_sales ws
    WHERE  ws.ws_ext_sales_price > 500
  )
SELECT
  cp.cp_catalog_page_number,
  sm.sm_type,
  hd_bill.hd_buy_potential,
  CASE
    WHEN td.t_minute < 10 THEN 'early'
    WHEN td.t_minute < 30 THEN 'mid'
    ELSE 'late'
  END                                          AS time_bucket,
  SUM(cs.cs_ext_sales_price)                  AS total_sales,
  COUNT(DISTINCT cs.cs_order_number)          AS orders,
  COALESCE(SUM(cr.cr_return_quantity), 0)     AS total_returns,
  ws_lateral.ws_sales_sum                     AS web_sales_sum
FROM
  catalog_sales cs
  INNER JOIN filtered_time td
    ON cs.cs_sold_time_sk = td.t_time_sk
  INNER JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  INNER JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  INNER JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  INNER JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  INNER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  INNER JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN web_sales ws
    ON ws.ws_sold_time_sk = cs.cs_sold_time_sk
  LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  LEFT JOIN LATERAL (
    SELECT SUM(ws2.ws_ext_sales_price) AS ws_sales_sum
    FROM   web_sales ws2
    WHERE  ws2.ws_sold_date_sk = cs.cs_sold_date_sk
  ) ws_lateral ON TRUE
  INNER JOIN intersect_orders io
    ON cs.cs_order_number = io.cs_order_number
WHERE
  NOT EXISTS (
    SELECT 1
    FROM   catalog_returns cr2
    WHERE  cr2.cr_order_number = cs.cs_order_number
      AND  cr2.cr_return_amount > 1000
  )
  AND cs.cs_ext_sales_price > 0
GROUP BY
  cp.cp_catalog_page_number,
  sm.sm_type,
  hd_bill.hd_buy_potential,
  td.t_minute,
  td.t_sub_shift,
  ws_lateral.ws_sales_sum
HAVING
  SUM(cs.cs_ext_sales_price) > 1000
ORDER BY
  total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
