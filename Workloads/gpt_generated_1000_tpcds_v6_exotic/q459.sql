WITH
  sales_union AS (
    SELECT
      i.i_category,
      s.s_state,
      td.t_hour,
      ss.ss_quantity AS quantity,
      ss.ss_net_paid AS net_paid,
      c.c_customer_sk,
      cd.cd_demo_sk,
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      'store' AS sales_channel
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE i.i_category = 'Electronics'
      AND ib.ib_lower_bound >= 50000
      AND td.t_hour BETWEEN 9 AND 17
  ),
  catalog_sales_union AS (
    SELECT
      i.i_category,
      NULL AS s_state,
      td.t_hour,
      cs.cs_quantity AS quantity,
      cs.cs_net_paid AS net_paid,
      c.c_customer_sk,
      cd.cd_demo_sk,
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                         AND cr.cr_item_sk = cs.cs_item_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cc.cc_state = 'CA'
      AND i.i_category = 'Electronics'
      AND ib.ib_lower_bound >= 50000
      AND r.r_reason_desc NOT LIKE '%product%'
      AND td.t_hour BETWEEN 9 AND 17
  ),
  web_sales_union AS (
    SELECT
      i.i_category,
      NULL AS s_state,
      td.t_hour,
      ws.ws_quantity AS quantity,
      ws.ws_net_paid AS net_paid,
      c.c_customer_sk,
      cd.cd_demo_sk,
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      'web' AS sales_channel
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    WHERE i.i_category = 'Electronics'
      AND ib.ib_lower_bound >= 50000
      AND td.t_hour BETWEEN 9 AND 17
  )
SELECT
  i_category,
  s_state,
  SUM(quantity) AS total_quantity,
  SUM(net_paid) AS total_net_paid,
  RANK() OVER (PARTITION BY s_state ORDER BY SUM(net_paid) DESC) AS state_sales_rank
FROM (
  SELECT * FROM sales_union
  UNION ALL
  SELECT * FROM catalog_sales_union
  UNION ALL
  SELECT * FROM web_sales_union
) all_sales
WHERE NOT EXISTS (
  SELECT 1
  FROM catalog_returns cr
  WHERE cr.cr_refunded_customer_sk = all_sales.c_customer_sk
)
GROUP BY ROLLUP(i_category, s_state)
HAVING SUM(net_paid) > 0
ORDER BY s_state, total_net_paid DESC
LIMIT 100
