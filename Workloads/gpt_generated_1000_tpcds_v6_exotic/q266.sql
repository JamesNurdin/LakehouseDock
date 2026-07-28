WITH
  base_catalog AS (
    SELECT
      d.d_date,
      i.i_item_sk,
      i.i_product_name,
      c.cs_quantity        AS quantity,
      c.cs_net_paid        AS net_paid,
      'catalog'            AS channel,
      r.r_reason_desc      AS return_reason,
      cc.cc_name           AS call_center_name,
      cp.cp_department     AS catalog_department,
      w.w_warehouse_name   AS warehouse_name,
      cu.c_email_address   AS customer_email,
      CAST(NULL AS varchar) AS web_url
    FROM catalog_sales c
    JOIN date_dim d               ON c.cs_sold_date_sk = d.d_date_sk
    JOIN item i                   ON c.cs_item_sk = i.i_item_sk
    JOIN call_center cc           ON c.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON c.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w              ON c.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer cu              ON c.cs_bill_customer_sk = cu.c_customer_sk
    LEFT JOIN catalog_returns cr  ON cr.cr_order_number = c.cs_order_number
                                 AND cr.cr_item_sk = c.cs_item_sk
    LEFT JOIN reason r            ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#13'
      AND c.cs_quantity > 0
  ),
  base_web AS (
    SELECT
      d.d_date,
      i.i_item_sk,
      i.i_product_name,
      ws.ws_quantity       AS quantity,
      ws.ws_net_paid       AS net_paid,
      'web'                AS channel,
      r.r_reason_desc      AS return_reason,
      CAST(NULL AS varchar) AS call_center_name,
      CAST(NULL AS varchar) AS catalog_department,
      w.w_warehouse_name   AS warehouse_name,
      cu.c_email_address   AS customer_email,
      wp.wp_url            AS web_url
    FROM web_sales ws
    JOIN date_dim d               ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i                   ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w              ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer cu              ON ws.ws_bill_customer_sk = cu.c_customer_sk
    LEFT JOIN web_returns wr      ON wr.wr_order_number = ws.ws_order_number
                                 AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r            ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#13'
      AND ws.ws_quantity > 0
  ),
  combined_sales AS (
    SELECT * FROM base_catalog
    UNION ALL
    SELECT * FROM base_web
  )
SELECT
  cs.d_date,
  cs.i_item_sk,
  cs.i_product_name,
  cs.channel,
  SUM(cs.net_paid)                     AS total_net_paid,
  COUNT(*)                             AS txn_count,
  CASE
    WHEN COUNT(*) > 10 THEN 'High Frequency'
    ELSE 'Low Frequency'
  END                                   AS freq_category,
  ROW_NUMBER() OVER (PARTITION BY cs.channel ORDER BY SUM(cs.net_paid) DESC) AS channel_rank,
  (SELECT AVG(cs2.net_paid)
   FROM combined_sales cs2
   WHERE cs2.i_item_sk = cs.i_item_sk) AS avg_item_net_paid,
  cs.call_center_name,
  cs.catalog_department,
  cs.warehouse_name,
  cs.customer_email,
  cs.web_url,
  d_ret.d_holiday,
  ca.ca_city,
  hd.hd_vehicle_count,
  ib.ib_lower_bound
FROM combined_sales cs
JOIN store_returns sr          ON sr.sr_item_sk = cs.i_item_sk
JOIN date_dim d_ret            ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN customer_address ca       ON sr.sr_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE d_ret.d_holiday = 'N'
  AND ca.ca_state = 'CA'
  AND ib.ib_lower_bound >= 20000
GROUP BY
  cs.d_date,
  cs.i_item_sk,
  cs.i_product_name,
  cs.channel,
  cs.call_center_name,
  cs.catalog_department,
  cs.warehouse_name,
  cs.customer_email,
  cs.web_url,
  d_ret.d_holiday,
  ca.ca_city,
  hd.hd_vehicle_count,
  ib.ib_lower_bound
HAVING SUM(cs.net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
