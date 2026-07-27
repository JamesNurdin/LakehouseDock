WITH inventory_agg AS (
    SELECT inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk
)
SELECT
    hd.hd_buy_potential,
    w.w_state,
    ia.total_qty,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(ws.ws_net_profit) AS web_profit,
    SUM(ss.ss_net_profit) AS store_profit,
    AVG(ws.ws_net_paid_inc_tax) AS avg_web_paid
FROM inventory_agg ia
JOIN warehouse w
    ON ia.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store_sales ss
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
  AND ws.ws_quantity > 1
  AND ss.ss_list_price > 20
  AND w.w_state IN ('CA', 'TX')
  AND r.r_reason_desc LIKE '%size%'
GROUP BY hd.hd_buy_potential, w.w_state, ia.total_qty
HAVING SUM(ws.ws_net_profit) > 1000
ORDER BY web_profit DESC
LIMIT 100
