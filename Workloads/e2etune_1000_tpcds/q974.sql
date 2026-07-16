WITH agg AS (
    SELECT
        hd_bill.hd_income_band_sk AS income_band,
        hd_bill.hd_vehicle_count AS bill_vehicle_cnt,
        hd_ship.hd_vehicle_count AS ship_vehicle_cnt,
        COUNT(*) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM web_sales ws
    JOIN household_demographics hd_bill
        ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship
        ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE hd_bill.hd_vehicle_count >= 2
      AND hd_ship.hd_vehicle_count >= 2
      AND hd_bill.hd_buy_potential IN ('1001-5000', '5001-10000')
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY
        hd_bill.hd_income_band_sk,
        hd_bill.hd_vehicle_count,
        hd_ship.hd_vehicle_count
    HAVING SUM(ws.ws_net_profit) > 1000
)
SELECT
    income_band,
    bill_vehicle_cnt,
    ship_vehicle_cnt,
    total_orders,
    total_net_profit,
    avg_net_profit,
    total_sales,
    avg_discount,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
    total_net_profit / total_sales AS profit_margin,
    SUM(total_net_profit) OVER (ORDER BY total_net_profit DESC) AS cumulative_profit
FROM agg
ORDER BY total_net_profit DESC
LIMIT 50
