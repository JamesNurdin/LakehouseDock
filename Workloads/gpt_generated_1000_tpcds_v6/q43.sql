WITH inv_agg AS (
    SELECT
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_date_sk
)
SELECT
    s.s_market_manager,
    COUNT(*) AS order_count,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_profit) AS avg_profit,
    SUM(i.total_qty) AS total_inventory_qty
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ship.d_date_sk
JOIN catalog_page cp
    ON cp.cp_end_date_sk = d_ship.d_date_sk
JOIN inv_agg i
    ON i.inv_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2002
  AND s.s_market_manager IN ('Richard Bell', 'David Smith')
  AND s.s_division_id = 1
  AND cd.cd_purchase_estimate BETWEEN 4000 AND 9000
  AND cc.cc_rec_start_date >= DATE '2000-01-01'
  AND cc.cc_rec_start_date <= DATE '2002-12-31'
  AND cp.cp_type = 'Electronic'
  AND i.total_qty > 1000
  AND ws.ws_item_sk IN (
        SELECT inv_item_sk
        FROM inventory
        WHERE inv_quantity_on_hand > 5000
    )
GROUP BY s.s_market_manager
HAVING AVG(ws.ws_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
