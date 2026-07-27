WITH sales_agg AS (
    SELECT
        w.w_city,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Low' END AS sales_category
    FROM store_sales ss
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451910 AND 2451919
      AND cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 50000
      AND w.w_gmt_offset = -5.00
    GROUP BY w.w_city, cd.cd_gender, hd.hd_buy_potential
)
SELECT *
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
