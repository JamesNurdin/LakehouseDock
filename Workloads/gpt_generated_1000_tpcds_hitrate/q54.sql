WITH base AS (
  SELECT
    s.s_state,
    i.i_brand,
    t.t_hour,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(ws.ws_net_profit) AS web_net_profit,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM store_sales ss
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
  JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
  JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
  JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
  WHERE t.t_hour IN (10, 14, 16)
    AND i.i_brand = 'Brand#23'
    AND s.s_state = 'CA'
    AND cp.cp_catalog_number BETWEEN 1 AND 5
    AND inv.inv_quantity_on_hand > 100
    AND EXISTS (
      SELECT 1 FROM catalog_page cp2
      WHERE cp2.cp_department = cp.cp_department
        AND cp2.cp_catalog_number > 5
    )
  GROUP BY ROLLUP (s.s_state, i.i_brand, t.t_hour)
)
SELECT *
FROM (
  SELECT
    s_state,
    i_brand,
    t_hour,
    store_net_profit,
    web_net_profit,
    catalog_return_amount,
    web_return_amount,
    store_orders,
    web_orders,
    ROW_NUMBER() OVER (PARTITION BY s_state, i_brand ORDER BY store_net_profit DESC) AS rn
  FROM base
) ranked
WHERE rn <= 3
ORDER BY s_state, i_brand, t_hour
LIMIT 100
