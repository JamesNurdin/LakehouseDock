WITH store_rev AS (
    SELECT
        d.d_date AS sales_date,
        s.s_store_name AS entity,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ib.ib_lower_bound >= 50000
    GROUP BY d.d_date, s.s_store_name
),
web_rev AS (
    SELECT
        d.d_date AS sales_date,
        wp.wp_url AS entity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND ib.ib_lower_bound >= 50000
    GROUP BY d.d_date, wp.wp_url
)
SELECT
    sales_date,
    entity,
    total_sales,
    transaction_count,
    'store' AS channel
FROM store_rev
UNION ALL
SELECT
    sales_date,
    entity,
    total_sales,
    transaction_count,
    'web' AS channel
FROM web_rev
ORDER BY sales_date DESC, total_sales DESC
LIMIT 100
