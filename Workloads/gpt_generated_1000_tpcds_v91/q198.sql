WITH base AS (
    SELECT
        d_sold.d_year AS year,
        sm.sm_type AS ship_mode_type,
        w.web_site_id AS web_site_id,
        cd_bill.cd_gender AS gender,
        cd_bill.cd_marital_status AS marital_status,
        hd_bill.hd_buy_potential AS buy_potential,
        CASE WHEN sm.sm_type = 'AIR' THEN 'Air' ELSE 'Other' END AS ship_mode_category,
        COALESCE(SUM(c.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(s.sr_return_amt), 0) AS total_store_returns,
        COUNT(*) AS total_transactions
    FROM catalog_sales c
    JOIN date_dim d_sold
        ON c.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer_demographics cd_bill
        ON c.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON c.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN ship_mode sm
        ON c.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        AND ws.ws_sold_date_sk = d_sold.d_date_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d_web_open
        ON w.web_open_date_sk = d_web_open.d_date_sk
    JOIN date_dim d_web_close
        ON w.web_close_date_sk = d_web_close.d_date_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN store_returns s
        ON s.sr_cdemo_sk = cd_bill.cd_demo_sk
        AND s.sr_hdemo_sk = hd_bill.hd_demo_sk
        AND s.sr_returned_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND sm.sm_type = 'AIR'
        AND cd_bill.cd_gender = 'M'
        AND hd_bill.hd_income_band_sk BETWEEN 1 AND 5
        AND wp.wp_autogen_flag = 'N'
        AND w.web_manager = 'Richard Fuchs'
    GROUP BY
        d_sold.d_year,
        sm.sm_type,
        w.web_site_id,
        cd_bill.cd_gender,
        cd_bill.cd_marital_status,
        hd_bill.hd_buy_potential,
        CASE WHEN sm.sm_type = 'AIR' THEN 'Air' ELSE 'Other' END
)
SELECT
    year,
    ship_mode_type,
    web_site_id,
    gender,
    marital_status,
    buy_potential,
    ship_mode_category,
    total_catalog_sales,
    total_web_sales,
    total_store_returns,
    total_transactions,
    (
        SELECT COALESCE(SUM(sr_sub.sr_return_amt), 0)
        FROM store_returns sr_sub
        JOIN date_dim d_sub ON sr_sub.sr_returned_date_sk = d_sub.d_date_sk
        JOIN customer_demographics cd_sub ON sr_sub.sr_cdemo_sk = cd_sub.cd_demo_sk
        WHERE d_sub.d_year = base.year
          AND cd_sub.cd_gender = base.gender
    ) AS total_return_amt_by_year_gender
FROM base
ORDER BY total_catalog_sales DESC
LIMIT 100
