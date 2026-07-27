WITH sales_by_time AS (
    SELECT
        td.t_sub_shift AS sub_shift,
        td.t_hour AS hour,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE
        td.t_sub_shift IN ('morning', 'afternoon', 'evening')
        AND td.t_hour BETWEEN 9 AND 18
        AND ss.ss_ext_wholesale_cost > 1000
        AND ss.ss_coupon_amt < 2000
        AND ws.ws_net_paid_inc_ship_tax >= 500
        AND ws.ws_ship_addr_sk NOT IN (1804633)
        AND ss.ss_ext_discount_amt <= 1500
    GROUP BY td.t_sub_shift, td.t_hour
)
SELECT
    sub_shift,
    hour,
    store_net_profit,
    web_net_profit,
    (store_net_profit + web_net_profit) AS total_net_profit,
    store_qty,
    web_qty,
    txn_count,
    (store_net_profit + web_net_profit) / txn_count AS avg_profit_per_txn
FROM sales_by_time
WHERE (store_net_profit + web_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
