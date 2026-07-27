WITH sr_hd AS (
    SELECT sr.*, hd_sr.hd_vehicle_count, hd_sr.hd_buy_potential
    FROM store_returns sr
    JOIN household_demographics hd_sr
      ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
)
SELECT
    i.i_category,
    i.i_brand,
    hd_ws.hd_buy_potential,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
FROM sr_hd sr
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN household_demographics hd_ws
  ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
WHERE EXISTS (
    SELECT 1
    FROM ship_mode sm
    WHERE sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
      AND sm.sm_carrier = 'UPS'
)
  AND i.i_category_id = 3
  AND i.i_current_price > 5.00
  AND sr.hd_vehicle_count >= 2
GROUP BY
    i.i_category,
    i.i_brand,
    hd_ws.hd_buy_potential
ORDER BY total_net_profit DESC
LIMIT 100
