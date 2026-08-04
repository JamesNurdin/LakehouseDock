WITH sales_enriched AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        d.d_year,
        d.d_qoy,
        d.d_current_week,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_quantity,
        hd.hd_demo_sk,
        hd.hd_vehicle_count,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE
            WHEN hd.hd_vehicle_count >= 3 THEN 'HighVehicle'
            WHEN hd.hd_vehicle_count = 2 THEN 'MediumVehicle'
            ELSE 'LowVehicle'
        END AS vehicle_category
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND d.d_qoy IN (1, 2)
      AND d.d_current_week = 'N'
      AND hd.hd_vehicle_count >= 0
      AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
      AND ib.ib_lower_bound >= 10000
      AND ws.ws_quantity > 0
      AND ws.ws_ext_sales_price > 0
),
agg AS (
    SELECT
        se.d_year,
        se.d_qoy,
        se.vehicle_category,
        se.hd_buy_potential,
        COUNT(DISTINCT se.ws_order_number) AS orders_cnt,
        SUM(se.ws_ext_sales_price) AS total_sales,
        SUM(se.ws_net_profit) AS total_profit,
        AVG(se.ws_ext_discount_amt) AS avg_discount
    FROM sales_enriched se
    GROUP BY
        se.d_year,
        se.d_qoy,
        se.vehicle_category,
        se.hd_buy_potential
    HAVING SUM(se.ws_net_profit) > 0
)
SELECT
    a.d_year,
    a.d_qoy,
    a.vehicle_category,
    a.hd_buy_potential,
    a.orders_cnt,
    a.total_sales,
    a.total_profit,
    a.avg_discount,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank_year
FROM agg a
ORDER BY a.d_year, profit_rank_year, a.total_sales DESC
LIMIT 100
