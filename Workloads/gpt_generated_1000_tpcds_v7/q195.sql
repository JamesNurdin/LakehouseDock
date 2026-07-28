WITH returns_agg AS (
    SELECT
        hd.hd_demo_sk,
        'return' AS metric,
        SUM(cr.cr_return_amount) AS amount
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk >= 10
    GROUP BY hd.hd_demo_sk
),
sales_agg AS (
    SELECT
        ws.ws_bill_hdemo_sk AS hd_demo_sk,
        'sale' AS metric,
        SUM(ws.ws_ext_sales_price) AS amount
    FROM web_sales ws
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE hd.hd_income_band_sk >= 10
      AND wp.wp_image_count >= 5
    GROUP BY ws.ws_bill_hdemo_sk
)
SELECT *
FROM returns_agg
UNION ALL
SELECT *
FROM sales_agg
ORDER BY hd_demo_sk, metric
