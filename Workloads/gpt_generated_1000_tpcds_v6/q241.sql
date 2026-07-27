WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        wp.wp_char_count,
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_warehouse_sk,
        ws.ws_order_number
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1220
      AND cd.cd_gender = 'F'
      AND cd.cd_education_status IN ('College', 'Graduate')
      AND hd.hd_vehicle_count >= 1
      AND wp.wp_char_count > 2000
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        cd_gender,
        cd_education_status,
        hd_income_band_sk,
        hd_vehicle_count,
        wp_char_count,
        ws_warehouse_sk,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_net_loss) AS total_net_loss,
        SUM(ws_net_paid_inc_ship_tax) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS distinct_orders
    FROM base
    GROUP BY
        d_year,
        d_month_seq,
        cd_gender,
        cd_education_status,
        hd_income_band_sk,
        hd_vehicle_count,
        wp_char_count,
        ws_warehouse_sk
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.cd_gender,
    a.cd_education_status,
    a.hd_income_band_sk,
    a.hd_vehicle_count,
    a.wp_char_count,
    a.total_return_amount,
    a.total_net_loss,
    a.total_sales,
    a.distinct_orders,
    RANK() OVER (PARTITION BY a.cd_gender ORDER BY a.total_return_amount DESC) AS gender_return_rank,
    DENSE_RANK() OVER (ORDER BY a.total_sales DESC) AS sales_dense_rank,
    ROW_NUMBER() OVER (ORDER BY a.total_sales DESC) AS overall_row_num,
    CASE
        WHEN a.hd_vehicle_count > 2 THEN 'HighVehicle'
        WHEN a.hd_vehicle_count = 2 THEN 'MediumVehicle'
        ELSE 'LowVehicle'
    END AS vehicle_category,
    (SELECT AVG(ws2.ws_net_profit)
     FROM web_sales ws2
     WHERE ws2.ws_warehouse_sk = a.ws_warehouse_sk) AS avg_warehouse_profit
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
