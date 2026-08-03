WITH wh_inventory AS (
    SELECT
        i.inv_warehouse_sk,
        i.inv_item_sk,
        i.inv_quantity_on_hand,
        w.w_warehouse_id,
        w.w_city,
        w.w_state,
        w.w_zip,
        w.w_country
    FROM inventory i
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.inv_quantity_on_hand > 0
      AND w.w_zip IN ('58828', '78370', '36098', '89275')
),
web_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_promo_sk,
        ws.ws_coupon_amt,
        ws.ws_wholesale_cost,
        ws.ws_sold_date_sk,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_city,
        w.w_state
    FROM web_sales ws
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_promo_sk IN (231, 549, 1178)
      AND ws.ws_coupon_amt > 50
      AND ws.ws_wholesale_cost BETWEEN 10 AND 70
      AND ws.ws_sold_date_sk BETWEEN 2450940 AND 2451085
)
SELECT
    jw.ws_order_number,
    jw.ws_item_sk,
    wi.w_warehouse_id,
    wi.w_city,
    wi.w_state,
    jw.ws_quantity,
    jw.ws_sales_price,
    jw.ws_net_profit,
    jw.ws_ext_discount_amt,
    CASE 
        WHEN jw.ws_net_profit > 1000 THEN 'HIGH'
        WHEN jw.ws_net_profit BETWEEN 0 AND 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    RANK() OVER (PARTITION BY wi.w_state ORDER BY jw.ws_net_profit DESC) AS state_profit_rank,
    ROW_NUMBER() OVER (PARTITION BY wi.w_city ORDER BY jw.ws_sales_price DESC) AS city_sales_rownum
FROM web_join jw
JOIN wh_inventory wi
    ON jw.w_warehouse_sk = wi.inv_warehouse_sk
ORDER BY wi.w_state, state_profit_rank
LIMIT 100
