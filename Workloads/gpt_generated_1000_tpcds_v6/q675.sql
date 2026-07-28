WITH sales_agg AS (
    SELECT
        c.c_customer_id AS customer_id,
        i.i_item_id AS item_id,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ws.ws_quantity) AS web_qty
    FROM store_sales ss
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE i.i_category = 'Sports'
      AND i.i_rec_end_date >= DATE '2000-01-01'
      AND sm.sm_code = 'AIR'
      AND w.w_state = 'CA'
      AND ws.ws_net_profit > 0
    GROUP BY c.c_customer_id, i.i_item_id
)
SELECT
    customer_id,
    SUM(store_profit + web_profit) AS total_profit,
    SUM(store_qty + web_qty) AS total_qty
FROM sales_agg
GROUP BY customer_id
HAVING SUM(store_profit + web_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
