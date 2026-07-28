WITH sales_agg AS (
    SELECT
        'sales' AS src,
        ws_site.web_name,
        CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_range,
        SUM(ws.ws_net_profit) AS total_amount
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ib.ib_lower_bound >= 50000
      AND ws_site.web_country = 'United States'
    GROUP BY ws_site.web_name,
             CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar))
    HAVING SUM(ws.ws_net_profit) > 10000
),
returns_agg AS (
    SELECT
        'returns' AS src,
        ws_site.web_name,
        CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar)) AS income_range,
        SUM(wr.wr_net_loss) * -1 AS total_amount   -- convert loss to positive amount for comparison
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ib.ib_lower_bound >= 50000
      AND ws_site.web_country = 'United States'
    GROUP BY ws_site.web_name,
             CONCAT(CAST(ib.ib_lower_bound AS varchar), '-', CAST(ib.ib_upper_bound AS varchar))
    HAVING SUM(wr.wr_net_loss) > 5000
)
SELECT DISTINCT src,
       web_name,
       income_range,
       total_amount
FROM (
    SELECT * FROM sales_agg
    UNION ALL
    SELECT * FROM returns_agg
) u
ORDER BY total_amount DESC
LIMIT 100
