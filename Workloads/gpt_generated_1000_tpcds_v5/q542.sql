WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_warehouse_sk,
        ws.ws_sold_time_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ship_date_sk,
        cd.cd_gender,
        hd.hd_buy_potential,
        w.w_warehouse_name,
        w.w_suite_number,
        w.w_warehouse_sq_ft,
        t.t_hour,
        t.t_meal_time
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_suite_number = 'Suite 260'
        AND w.w_warehouse_sq_ft > 400000
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '5001-10000'
        AND t.t_meal_time = 'Lunch'
        AND ws.ws_ship_date_sk BETWEEN 2451450 AND 2451500
        AND ws.ws_quantity >= 2
)
SELECT
    sd.w_warehouse_name,
    sd.t_hour,
    sd.cd_gender,
    sd.hd_buy_potential,
    COUNT(DISTINCT sd.ws_order_number) AS order_count,
    SUM(sd.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(r.wr_net_loss, 0)) AS total_return_loss,
    AVG(sd.ws_quantity) AS avg_quantity,
    MIN(sd.ws_quantity) AS min_quantity,
    MAX(sd.ws_quantity) AS max_quantity
FROM sales_data sd
LEFT JOIN web_returns r
    ON r.wr_order_number = sd.ws_order_number
WHERE EXISTS (
    SELECT 1
    FROM inventory i
    WHERE i.inv_warehouse_sk = sd.ws_warehouse_sk
      AND i.inv_quantity_on_hand > 1000
)
GROUP BY
    sd.w_warehouse_name,
    sd.t_hour,
    sd.cd_gender,
    sd.hd_buy_potential
ORDER BY total_net_profit DESC
LIMIT 100
