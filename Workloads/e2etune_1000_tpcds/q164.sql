WITH profit_by_state_channel AS (
    SELECT w.w_state AS w_state,
           p.p_channel_tv AS channel_tv,
           SUM(ws.ws_net_profit) AS total_profit,
           SUM(ws.ws_quantity) AS total_qty,
           COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
           AVG(ws.ws_ext_discount_amt) AS avg_discount,
           AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE hd.hd_income_band_sk >= 4
      AND p.p_discount_active = 'Y'
      AND w.w_state IN ('CA', 'TX', 'NY', 'FL')
      AND inv.inv_date_sk BETWEEN 2458000 AND 2458300
    GROUP BY w.w_state, p.p_channel_tv
)
SELECT w_state,
       channel_tv,
       total_profit,
       total_qty,
       order_cnt,
       avg_discount,
       avg_inventory_on_hand,
       RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM profit_by_state_channel
WHERE total_profit > 100000
ORDER BY profit_rank
LIMIT 100
