WITH cat_returns AS (
        SELECT
            'catalog' AS source,
            cd.cd_gender AS gender,
            SUM(cr.cr_return_amount) AS total_amount
        FROM tpcds.catalog_returns cr
        JOIN tpcds.customer_demographics cd
          ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.household_demographics hd
          ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND hd.hd_income_band_sk BETWEEN 1 AND 5
        GROUP BY cd.cd_gender
    ),
    store_returns_agg AS (
        SELECT
            'store' AS source,
            cd.cd_gender AS gender,
            SUM(sr.sr_return_amt) AS total_amount
        FROM tpcds.store_returns sr
        JOIN tpcds.customer_demographics cd
          ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.household_demographics hd
          ON sr.sr_hdemo_sk = hd.hd_demo_sk
        WHERE cd.cd_gender = 'F'
          AND hd.hd_income_band_sk BETWEEN 1 AND 5
        GROUP BY cd.cd_gender
    ),
    web_sales_agg AS (
        SELECT
            'web' AS source,
            cd.cd_gender AS gender,
            SUM(ws.ws_ext_sales_price) AS total_amount
        FROM tpcds.web_sales ws
        JOIN tpcds.customer_demographics cd
          ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN tpcds.household_demographics hd
          ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.web_site w
          ON ws.ws_web_site_sk = w.web_site_sk
        WHERE cd.cd_gender = 'F'
          AND w.web_rec_end_date = DATE '2000-08-15'
        GROUP BY cd.cd_gender
    )
SELECT source, gender, total_amount
FROM cat_returns
UNION ALL
SELECT source, gender, total_amount
FROM store_returns_agg
UNION ALL
SELECT source, gender, total_amount
FROM web_sales_agg
ORDER BY total_amount DESC
LIMIT 100
