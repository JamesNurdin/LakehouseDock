WITH base_sales AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_web_page_sk,
        ws.ws_ship_mode_sk,
        ws.ws_warehouse_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_tax,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_sales_price
    FROM web_sales ws
    WHERE ws.ws_ext_tax > 50
),
customer_sales AS (
    SELECT
        bs.ws_bill_customer_sk AS cust_sk,
        SUM(bs.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM base_sales bs
    GROUP BY bs.ws_bill_customer_sk
),
agg AS (
    SELECT
        w.w_warehouse_id AS w_warehouse_id,
        sm.sm_type AS sm_type,
        cd.cd_gender AS cd_gender,
        COUNT(DISTINCT bs.ws_order_number) AS orders,
        SUM(bs.ws_net_profit) AS sum_profit,
        AVG(bs.ws_ext_tax) AS avg_tax,
        CASE WHEN SUM(bs.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM base_sales bs
    JOIN time_dim td ON bs.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON bs.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON bs.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON bs.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON bs.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON bs.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN customer_sales cs ON cs.cust_sk = c.c_customer_sk
    WHERE
        td.t_hour BETWEEN 9 AND 17
        AND w.w_zip = '38048'
        AND cd.cd_purchase_estimate > 5000
        AND c.c_preferred_cust_flag = 'Y'
        AND EXISTS (
            SELECT 1 FROM inventory i2
            WHERE i2.inv_warehouse_sk = w.w_warehouse_sk
              AND i2.inv_quantity_on_hand > 200
        )
    GROUP BY
        w.w_warehouse_id,
        sm.sm_type,
        cd.cd_gender
    HAVING SUM(bs.ws_net_profit) > 0
)
SELECT
    a.w_warehouse_id,
    a.sm_type,
    a.cd_gender,
    a.orders,
    a.sum_profit,
    a.avg_tax,
    a.profit_flag,
    SUM(a.sum_profit) OVER (PARTITION BY a.w_warehouse_id ORDER BY a.sum_profit DESC) AS running_profit,
    RANK() OVER (PARTITION BY a.w_warehouse_id ORDER BY a.sum_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.sum_profit DESC
LIMIT 100
