WITH filtered_dates AS (
        SELECT d_date_sk, d_year, d_month_seq
        FROM date_dim
        WHERE d_year = 2001
    ),
    promo_web_sales AS (
        SELECT
            fd.d_year,
            fd.d_month_seq AS month,
            'web_sales' AS source,
            SUM(ws.ws_ext_sales_price) AS total_amount
        FROM web_sales ws
        JOIN filtered_dates fd ON ws.ws_sold_date_sk = fd.d_date_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
        WHERE p.p_discount_active = 'Y'
        GROUP BY fd.d_year, fd.d_month_seq
    ),
    store_returns_agg AS (
        SELECT
            fd.d_year,
            fd.d_month_seq AS month,
            'store_returns' AS source,
            SUM(sr.sr_refunded_cash + sr.sr_fee) AS total_amount
        FROM store_returns sr
        JOIN filtered_dates fd ON sr.sr_returned_date_sk = fd.d_date_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        WHERE hd.hd_vehicle_count > 2
        GROUP BY fd.d_year, fd.d_month_seq
    )
SELECT *
FROM promo_web_sales
UNION ALL
SELECT *
FROM store_returns_agg
ORDER BY d_year, month, source
LIMIT 100
