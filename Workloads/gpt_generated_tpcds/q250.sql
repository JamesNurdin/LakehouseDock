WITH sales_by_item_demo AS (
    SELECT
        i.i_category,
        i.i_brand,
        hd_bill.hd_buy_potential,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    -- Optional: join shipping household demographics if needed
    -- JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE i.i_current_price > 0
      AND hd_bill.hd_vehicle_count > 0
)
SELECT
    i_category,
    i_brand,
    hd_buy_potential,
    COUNT(DISTINCT ws_order_number) AS num_orders,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_quantity) AS avg_quantity,
    SUM(ws_ext_discount_amt) / NULLIF(SUM(ws_ext_sales_price), 0) AS discount_rate,
    RANK() OVER (PARTITION BY hd_buy_potential ORDER BY SUM(ws_net_profit) DESC) AS profit_rank_within_buy_potential
FROM sales_by_item_demo
GROUP BY i_category, i_brand, hd_buy_potential
HAVING SUM(ws_net_profit) > 0
ORDER BY profit_rank_within_buy_potential, total_profit DESC
LIMIT 50
