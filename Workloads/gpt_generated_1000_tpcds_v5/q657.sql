WITH cs AS (
    SELECT
        cs.cs_order_number,
        cs.cs_call_center_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_net_profit
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 1000
),
ws AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_bill_addr_sk,
        ws.ws_ship_addr_sk,
        ws.ws_net_profit
    FROM web_sales ws
    WHERE ws.ws_net_profit < 500
),
inv AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand > 0
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    d_cs.d_date,
    cs.cs_order_number,
    cs.cs_net_profit,
    ws.ws_order_number,
    ws.ws_net_profit,
    inv.inv_quantity_on_hand,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_call_center_id ORDER BY cs.cs_net_profit DESC) AS profit_rank,
    CASE
        WHEN cs.cs_net_profit > (
            SELECT avg(ws2.ws_net_profit)
            FROM web_sales ws2
            WHERE ws2.ws_sold_date_sk = cs.cs_sold_date_sk
        ) THEN 'Above Avg WS Profit'
        ELSE 'Below Avg WS Profit'
    END AS profit_comparison
FROM cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_cs
    ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs
    ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
LEFT JOIN ws
    ON ws.ws_sold_date_sk = cs.cs_sold_date_sk
LEFT JOIN inv
    ON inv.inv_date_sk = d_cs.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_cs.d_date_sk
JOIN time_dim t_sr
    ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN customer_address ca_sr
    ON sr.sr_addr_sk = ca_sr.ca_address_sk
JOIN web_sales ws_main
    ON ws_main.ws_sold_date_sk = d_cs.d_date_sk
JOIN date_dim d_ws
    ON ws_main.ws_sold_date_sk = d_ws.d_date_sk
JOIN time_dim t_ws
    ON ws_main.ws_sold_time_sk = t_ws.t_time_sk
JOIN customer_address ca_ws_bill
    ON ws_main.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship
    ON ws_main.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
WHERE cc.cc_state = 'CA'
  AND d_cs.d_year = 2001
  AND ca_bill.ca_state = 'TX'
  AND ca_ship.ca_state = 'TX'
  AND ca_ws_bill.ca_state = 'TX'
  AND ca_ws_ship.ca_state = 'TX'
  AND ca_sr.ca_state = 'TX'
LIMIT 100
