WITH sales_agg AS (
    SELECT
        w.w_warehouse_name AS warehouse_name,
        dd_sold.d_quarter_name AS quarter_name,
        CASE WHEN ws.ws_net_profit > 5000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        SUM(ws.ws_net_profit) AS quarter_profit,
        SUM(ws.ws_ext_sales_price) AS quarter_sales,
        COUNT(*) AS transaction_cnt
    FROM web_sales ws
    JOIN date_dim dd_sold
        ON ws.ws_sold_date_sk = dd_sold.d_date_sk
    JOIN date_dim dd_ship
        ON ws.ws_ship_date_sk = dd_ship.d_date_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE
        dd_sold.d_year = 1998
        AND dd_sold.d_quarter_name = '1998Q1'
        AND dd_sold.d_current_quarter = 'Y'
        AND hd.hd_income_band_sk IN (10, 16, 20)
        AND hd.hd_vehicle_count >= 1
        AND td.t_hour BETWEEN 9 AND 17
        AND ws.ws_ext_sales_price > 1000
        AND ws.ws_net_profit > 0
    GROUP BY
        w.w_warehouse_name,
        dd_sold.d_quarter_name,
        CASE WHEN ws.ws_net_profit > 5000 THEN 'HIGH' ELSE 'LOW' END
)
SELECT
    warehouse_name,
    AVG(quarter_profit) AS avg_quarter_profit,
    SUM(transaction_cnt) AS total_transactions
FROM sales_agg
WHERE profit_category = 'HIGH' AND quarter_profit > 10000
GROUP BY warehouse_name
ORDER BY avg_quarter_profit DESC
LIMIT 100
