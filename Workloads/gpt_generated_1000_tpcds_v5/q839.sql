WITH store_agg AS (
    SELECT
        cp.cp_department AS department,
        hd.hd_buy_potential AS buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(cr.cr_net_loss) AS total_return_loss,
        CAST(NULL AS decimal(7,2)) AS total_web_return,
        CAST(NULL AS decimal(7,2)) AS total_web_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_count
    FROM tpcds.store_sales ss
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE ss.ss_wholesale_cost > 30.00
      AND ss.ss_coupon_amt < 5000.00
      AND hd.hd_dep_count BETWEEN 1 AND 5
      AND hd.hd_buy_potential IN ('0-500', '501-1000')
      AND cr.cr_return_tax > 50.00
    GROUP BY cp.cp_department, hd.hd_buy_potential
),
web_agg AS (
    SELECT
        cp.cp_department AS department,
        hd.hd_buy_potential AS buy_potential,
        CAST(NULL AS decimal(7,2)) AS total_sales,
        CAST(NULL AS decimal(7,2)) AS total_return_loss,
        SUM(wr.wr_return_amt_inc_tax) AS total_web_return,
        SUM(wr.wr_net_loss) AS total_web_loss,
        COUNT(DISTINCT wr.wr_order_number) AS unique_count
    FROM tpcds.web_returns wr
    JOIN tpcds.household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_tax > 40.00
      AND wr.wr_return_amt > 20.00
      AND hd.hd_income_band_sk IN (3, 4, 5)
      AND hd.hd_vehicle_count >= 1
      AND cp.cp_type = 'Promotion'
    GROUP BY cp.cp_department, hd.hd_buy_potential
)
SELECT DISTINCT
    department,
    buy_potential,
    total_sales,
    total_return_loss,
    total_web_return,
    total_web_loss,
    unique_count
FROM (
    SELECT * FROM store_agg
    UNION ALL
    SELECT * FROM web_agg
) AS combined
ORDER BY department ASC, total_sales DESC
LIMIT 100
