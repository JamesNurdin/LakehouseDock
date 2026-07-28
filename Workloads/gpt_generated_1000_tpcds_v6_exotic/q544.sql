WITH joined AS (
  SELECT
    s.s_state,
    i.i_category,
    td.t_hour,
    ws.ws_net_paid,
    ws.ws_net_profit,
    ss.ss_net_paid AS store_net_paid,
    ss.ss_net_profit AS store_net_profit,
    inv.inv_quantity_on_hand,
    p.p_discount_active
  FROM catalog_sales cs
  JOIN time_dim td                         ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN item i                              ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p                         ON cs.cs_promo_sk = p.p_promo_sk
  JOIN ship_mode sm                        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN call_center cc                      ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer_address ca_bill            ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN store_sales ss                      ON ss.ss_item_sk = i.i_item_sk
  JOIN customer_address ca_store           ON ss.ss_addr_sk = ca_store.ca_address_sk
  JOIN time_dim td_store                   ON ss.ss_sold_time_sk = td_store.t_time_sk
  JOIN store s                             ON ss.ss_store_sk = s.s_store_sk
  JOIN web_sales ws                       ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site wsit                       ON ws.ws_web_site_sk = wsit.web_site_sk
  JOIN web_returns wr                     ON wr.wr_order_number = ws.ws_order_number
  JOIN inventory inv                       ON inv.inv_item_sk = i.i_item_sk
  WHERE td.t_hour BETWEEN 8 AND 17
    AND i.i_category = 'Sports'
    AND p.p_discount_active = 'Y'
    AND s.s_state = 'CA'
    AND inv.inv_quantity_on_hand > 500
),
agg AS (
  SELECT
    s_state,
    i_category,
    t_hour,
    SUM(ws_net_paid)               AS total_ws_paid,
    SUM(ws_net_profit)             AS total_ws_profit,
    SUM(store_net_paid)            AS total_ss_paid,
    SUM(store_net_profit)          AS total_ss_profit,
    SUM(inv_quantity_on_hand)      AS total_inventory,
    CASE
      WHEN SUM(ws_net_profit) + SUM(store_net_profit) > 0 THEN 'Profit'
      ELSE 'Loss'
    END                             AS profit_flag
  FROM joined
  GROUP BY ROLLUP (s_state, i_category, t_hour)
)
SELECT
  s_state,
  i_category,
  t_hour,
  total_ws_paid,
  total_ws_profit,
  total_ss_paid,
  total_ss_profit,
  total_inventory,
  profit_flag,
  RANK() OVER (PARTITION BY s_state ORDER BY (total_ws_profit + total_ss_profit) DESC) AS state_profit_rank
FROM agg
ORDER BY s_state, i_category, t_hour
