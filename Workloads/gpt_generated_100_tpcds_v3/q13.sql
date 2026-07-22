WITH sales_agg AS (
    SELECT
        ws_site.web_name AS website_name,
        td.t_hour AS hour_of_day,
        'sales' AS metric_type,
        SUM(ws.ws_net_paid) AS total_amount,
        COUNT(*) AS transaction_count
    FROM web_sales ws
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_income_band_sk = 4
        AND ws_site.web_tax_percentage > 0.05
        AND td.t_hour BETWEEN 9 AND 12
        AND i.i_category = 'Sports'
        AND EXISTS (
            SELECT 1
            FROM promotion p
            WHERE p.p_promo_sk = ws.ws_promo_sk
              AND p.p_discount_active = 'Y'
        )
    GROUP BY
        ws_site.web_name,
        td.t_hour
),
returns_agg AS (
    SELECT
        ws_site.web_name AS website_name,
        td.t_hour AS hour_of_day,
        'returns' AS metric_type,
        SUM(wr.wr_return_amt) AS total_amount,
        COUNT(*) AS transaction_count
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_income_band_sk = 4
        AND ws_site.web_tax_percentage > 0.05
        AND td.t_hour BETWEEN 9 AND 12
        AND i.i_category = 'Sports'
    GROUP BY
        ws_site.web_name,
        td.t_hour
)
SELECT
    website_name,
    hour_of_day,
    metric_type,
    total_amount,
    transaction_count
FROM sales_agg
UNION ALL
SELECT
    website_name,
    hour_of_day,
    metric_type,
    total_amount,
    transaction_count
FROM returns_agg
LIMIT 100
