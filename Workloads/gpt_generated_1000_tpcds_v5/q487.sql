WITH sales_agg AS (
    SELECT
        cs.cs_bill_hdemo_sk AS cs_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk AS ws_ship_hdemo_sk,
        SUM(cs.cs_net_paid) AS sum_cs_net_paid,
        SUM(ws.ws_net_paid) AS sum_ws_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS cnt_cs_orders,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_ws_orders
    FROM catalog_sales cs
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN household_demographics hd_bill_cs
        ON cs.cs_bill_hdemo_sk = hd_bill_cs.hd_demo_sk
    JOIN household_demographics hd_ship_cs
        ON cs.cs_ship_hdemo_sk = hd_ship_cs.hd_demo_sk
    JOIN warehouse wh_cs
        ON cs.cs_warehouse_sk = wh_cs.w_warehouse_sk
    -- Cross‑join with web_sales and its dimensions (no direct join rule between catalog_sales and web_sales)
    CROSS JOIN (
        SELECT ws.*
        FROM web_sales ws
        JOIN time_dim td_ws
            ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN household_demographics hd_bill_ws
            ON ws.ws_bill_hdemo_sk = hd_bill_ws.hd_demo_sk
        JOIN household_demographics hd_ship_ws
            ON ws.ws_ship_hdemo_sk = hd_ship_ws.hd_demo_sk
        JOIN warehouse wh_ws
            ON ws.ws_warehouse_sk = wh_ws.w_warehouse_sk
        JOIN web_page wp_ws
            ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
    ) ws
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
    JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN household_demographics hd_refunded_wr
        ON wr.wr_refunded_hdemo_sk = hd_refunded_wr.hd_demo_sk
    JOIN household_demographics hd_returning_wr
        ON wr.wr_returning_hdemo_sk = hd_returning_wr.hd_demo_sk
    JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    WHERE td_cs.t_hour BETWEEN 8 AND 14
      AND hd_bill_cs.hd_buy_potential = '5001-10000'
      AND wh_cs.w_state = 'CA'
      AND cs.cs_promo_sk IN (73, 1057)
      AND ws.ws_quantity > 5
      AND wr.wr_return_quantity > 0
    GROUP BY GROUPING SETS (
        (cs.cs_bill_hdemo_sk, ws.ws_ship_hdemo_sk),
        (cs.cs_bill_hdemo_sk),
        (ws.ws_ship_hdemo_sk),
        ()
    )
)
SELECT
    cs_bill_hdemo_sk,
    ws_ship_hdemo_sk,
    sum_cs_net_paid,
    sum_ws_net_paid,
    cnt_cs_orders,
    cnt_ws_orders,
    (sum_cs_net_paid + sum_ws_net_paid) / NULLIF(cnt_cs_orders + cnt_ws_orders, 0) AS avg_net_paid_per_order
FROM sales_agg
WHERE (sum_cs_net_paid + sum_ws_net_paid) > 10000
ORDER BY avg_net_paid_per_order DESC
LIMIT 100
