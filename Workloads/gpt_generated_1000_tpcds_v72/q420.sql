WITH ws_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit
    FROM web_sales ws
    JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_year = 2001
    GROUP BY ws.ws_item_sk, ws.ws_sold_date_sk
)
SELECT
    i.i_category,
    i.i_class,
    cc.cc_name,
    d_sold.d_year,
    SUM(cs.cs_net_paid) AS catalog_net_paid,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS total_inventory_qty,
    SUM(ws_agg.web_net_paid) AS web_net_paid,
    SUM(ws_agg.web_net_profit) AS web_net_profit
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN (
    SELECT inv.inv_item_sk, inv.inv_date_sk, inv.inv_warehouse_sk, inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
) inv
    ON inv.inv_item_sk = cs.cs_item_sk
   AND inv.inv_date_sk = cs.cs_sold_date_sk
   AND inv.inv_warehouse_sk = cs.cs_warehouse_sk
JOIN ws_agg ON ws_agg.ws_item_sk = cs.cs_item_sk
          AND ws_agg.ws_sold_date_sk = cs.cs_sold_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_class = 'infants'
GROUP BY i.i_category, i.i_class, cc.cc_name, d_sold.d_year
HAVING SUM(cs.cs_net_paid) > 10000
ORDER BY catalog_net_paid DESC
LIMIT 100
