WITH return_data AS (
    SELECT
        'return' AS transaction_type,
        cr.cr_return_amount AS trans_amount,
        cc.cc_name AS location_name,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'high' ELSE 'low' END AS amount_category,
        cd.cd_gender AS gender,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper
    FROM catalog_returns cr
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_rec_end_date = DATE '2000-12-31'
      AND cr.cr_return_amount > (
          SELECT avg(cr2.cr_return_amount)
          FROM catalog_returns cr2
          WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
      )
),
sale_data AS (
    SELECT
        'sale' AS transaction_type,
        ws.ws_ext_sales_price AS trans_amount,
        CAST(null AS varchar) AS location_name,
        CASE WHEN ws.ws_ext_sales_price > 500 THEN 'high' ELSE 'low' END AS amount_category,
        cd.cd_gender AS gender,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE ws.ws_ext_sales_price > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr_exist
          WHERE cr_exist.cr_returning_cdemo_sk = cd.cd_demo_sk
            AND cr_exist.cr_return_amount > 2000
      )
)
SELECT
    transaction_type,
    trans_amount,
    location_name,
    amount_category,
    gender,
    income_lower,
    income_upper
FROM return_data
UNION ALL
SELECT
    transaction_type,
    trans_amount,
    location_name,
    amount_category,
    gender,
    income_lower,
    income_upper
FROM sale_data
ORDER BY trans_amount DESC
LIMIT 100
