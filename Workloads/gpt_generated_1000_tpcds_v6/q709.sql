WITH sales_agg AS (
    SELECT
        i.i_manufact_id AS manufact_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        ca_bill.ca_state AS state,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_qty,
        COUNT(*) AS order_count
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE ca_bill.ca_country = 'United States'
      AND i.i_category_id IN (3, 4, 6)
      AND t.t_time >= 12
    GROUP BY i.i_manufact_id, sm.sm_ship_mode_id, ca_bill.ca_state
)
SELECT
    manufact_id,
    ship_mode_id,
    state,
    total_profit,
    total_qty,
    order_count,
    total_profit / NULLIF(total_qty, 0) AS profit_per_unit
FROM sales_agg
WHERE total_profit > 1000
ORDER BY total_profit DESC
LIMIT 100
