WITH joined AS (
    SELECT
        d.d_date,
        d.d_year,
        s.s_store_name,
        cc.cc_name AS call_center_name,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        ws.ws_order_number,
        ws.ws_net_profit,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        t.t_hour,
        ws.ws_sales_price,
        CASE WHEN ws.ws_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        (SELECT SUM(inv2.inv_quantity_on_hand)
         FROM inventory inv2
         WHERE inv2.inv_warehouse_sk = w.w_warehouse_sk) AS total_warehouse_inventory
    FROM date_dim d
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w
        ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN time_dim t
        ON t.t_time_sk = cr.cr_returned_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we
        ON we.web_site_sk = ws.ws_web_site_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND d.d_holiday = 'N'
      AND cc.cc_city = 'Georgetown'
)

SELECT DISTINCT
    u.profit_category,
    u.s_store_name,
    u.d_year,
    u.ws_order_number,
    u.ws_net_profit,
    u.total_warehouse_inventory,
    ROW_NUMBER() OVER (PARTITION BY u.s_store_name ORDER BY u.ws_net_profit DESC) AS profit_rank
FROM (
    SELECT * FROM joined
    UNION ALL
    SELECT * FROM joined WHERE ws_net_profit < 0
) AS u
WHERE EXISTS (
    SELECT 1
    FROM inventory inv_chk
    WHERE inv_chk.inv_warehouse_sk = u.w_warehouse_sk
      AND inv_chk.inv_quantity_on_hand > 0
)
ORDER BY profit_rank
LIMIT 100
