WITH inv_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    w.w_warehouse_name,
    i.i_item_id,
    i.i_product_name,
    cc.cc_name AS call_center_name,
    cp.cp_description AS catalog_page_desc,
    cs.cs_net_profit AS catalog_net_profit,
    ss.ss_net_profit AS store_net_profit,
    ws.ws_net_profit AS web_net_profit,
    inv_agg.total_on_hand,
    (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) AS combined_net_profit,
    RANK() OVER (PARTITION BY s.s_state ORDER BY (cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit) DESC) AS state_profit_rank,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS catalog_profit_flag
FROM store s
JOIN store_sales ss
  ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
  ON sr.sr_store_sk = s.s_store_sk
  AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs
  ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
  ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim t
  ON cs.cs_sold_time_sk = t.t_time_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
  AND ws.ws_warehouse_sk = w.w_warehouse_sk
  AND ws.ws_sold_time_sk = t.t_time_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
  AND wr.wr_item_sk = i.i_item_sk
  AND wr.wr_returned_time_sk = t.t_time_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN inv_agg
  ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    t.t_hour IN (8, 16)
    AND s.s_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND cc.cc_market_manager = 'John Doe'
ORDER BY s.s_state, state_profit_rank, s.s_store_id
LIMIT 100
