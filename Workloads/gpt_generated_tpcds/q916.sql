WITH sales_agg AS (
    SELECT
        t.t_hour,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        avg(cs.cs_ext_discount_amt) AS avg_discount_amount,
        sum(cs.cs_quantity) AS total_quantity,
        count(*) AS order_count
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd_bill
        ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    WHERE cs.cs_net_profit > 0
      AND t.t_hour BETWEEN 8 AND 20
    GROUP BY t.t_hour,
             cd_bill.cd_gender,
             cd_ship.cd_gender,
             hd_bill.hd_income_band_sk,
             hd_ship.hd_income_band_sk
)
SELECT
    t_hour AS hour_of_day,
    bill_gender,
    ship_gender,
    bill_income_band,
    ship_income_band,
    total_net_paid,
    total_net_profit,
    avg_discount_amount,
    total_quantity,
    order_count,
    rank() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net_profit DESC
LIMIT 100
