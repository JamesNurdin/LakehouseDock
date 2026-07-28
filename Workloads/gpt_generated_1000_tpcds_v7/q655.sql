SELECT
    cs.cs_order_number,
    d.d_year,
    cd.cd_gender,
    i.i_item_id,
    i.i_category,
    sm.sm_ship_mode_id,
    inv.inv_quantity_on_hand,
    s.s_store_name,
    ws.ws_quantity,
    cs.cs_net_profit,
    SUM(cs.cs_net_profit) OVER (PARTITION BY cd.cd_gender ORDER BY cs.cs_net_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit,
    RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cs.cs_net_profit DESC) AS profit_rank
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
 AND inv.inv_item_sk = i.i_item_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
 AND ws.ws_item_sk = i.i_item_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
WHERE d.d_year = 2001
  AND cd.cd_marital_status = 'M'
  AND sm.sm_code = 'AIR'
  AND i.i_manager_id = 21
  AND inv.inv_quantity_on_hand > 50
  AND s.s_state = 'CA'
  AND ws.ws_quantity > 2
