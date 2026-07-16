WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451088
),
joined AS (
    SELECT
        t.t_hour,
        cd_bill.cd_gender AS bill_gender,
        hd_bill.hd_income_band_sk AS bill_income_band,
        cd_ship.cd_gender AS ship_gender,
        hd_ship.hd_income_band_sk AS ship_income_band,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt
    FROM filtered_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cd_bill.cd_education_status = 'College'
      AND hd_bill.hd_buy_potential = 'HIGH'
      AND cd_ship.cd_education_status = 'College'
      AND hd_ship.hd_buy_potential = 'HIGH'
),
aggregated AS (
    SELECT
        t_hour,
        bill_gender,
        bill_income_band,
        COUNT(DISTINCT ws_order_number) AS distinct_orders,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_ext_discount_amt) AS avg_discount,
        AVG(CASE WHEN ship_gender = 'M' THEN ws_ext_discount_amt END) AS avg_discount_ship_m,
        AVG(CASE WHEN ship_gender = 'F' THEN ws_ext_discount_amt END) AS avg_discount_ship_f
    FROM joined
    GROUP BY t_hour, bill_gender, bill_income_band
)
SELECT
    t_hour,
    bill_gender,
    bill_income_band,
    distinct_orders,
    total_profit,
    avg_discount,
    avg_discount_ship_m,
    avg_discount_ship_f,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 100
