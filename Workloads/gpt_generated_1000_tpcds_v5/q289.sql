WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_ship_tax,
        ws.ws_bill_customer_sk,
        c.c_email_address,
        hd.hd_income_band_sk,
        td.t_hour,
        td.t_shift,
        regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) AS email_domain,
        CASE
            WHEN regexp_like(c.c_email_address, '@.*\\.org$') THEN 'ORG'
            ELSE 'NON_ORG'
        END AS email_type,
        CASE
            WHEN regexp_extract(c.c_email_address, '@([^.]*)\\.', 1) = 'gmail' THEN 'Gmail'
            ELSE 'Other'
        END AS email_category
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE ws.ws_net_paid_inc_ship_tax > 0
),

returns_agg AS (
    SELECT
        wr.wr_order_number,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    GROUP BY wr.wr_order_number
),

aggregated AS (
    SELECT
        sd.t_hour,
        sd.t_shift,
        sd.hd_income_band_sk,
        SUM(sd.ws_net_paid_inc_ship_tax) AS total_sales,
        SUM(COALESCE(r.total_return_qty, 0)) AS total_returns,
        COUNT(DISTINCT sd.ws_bill_customer_sk) AS unique_customers,
        SUM(CASE WHEN sd.email_category = 'Gmail' THEN 1 ELSE 0 END) AS gmail_customers,
        SUM(CASE WHEN sd.email_type = 'ORG' THEN 1 ELSE 0 END) AS org_email_customers
    FROM sales_data sd
    LEFT JOIN returns_agg r ON sd.ws_order_number = r.wr_order_number
    GROUP BY sd.t_hour, sd.t_shift, sd.hd_income_band_sk
)
SELECT
    a.t_hour,
    a.t_shift,
    a.hd_income_band_sk,
    a.total_sales,
    a.total_returns,
    a.unique_customers,
    a.gmail_customers,
    a.org_email_customers,
    CASE
        WHEN a.total_returns > 0 THEN 'Has Returns'
        ELSE 'No Returns'
    END AS return_flag,
    row_number() OVER (PARTITION BY a.hd_income_band_sk ORDER BY a.total_sales DESC) AS sales_rank,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_return_quantity > 0) AS total_return_events
FROM aggregated a
WHERE EXISTS (
    SELECT 1
    FROM sales_data sd2
    WHERE sd2.t_hour = a.t_hour
      AND sd2.t_shift = a.t_shift
      AND sd2.hd_income_band_sk = a.hd_income_band_sk
      AND sd2.email_type = 'ORG'
)
ORDER BY a.total_sales DESC
LIMIT 100
