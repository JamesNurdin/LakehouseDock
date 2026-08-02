WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_country,
        c.c_salutation,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_wholesale_cost) AS total_wholesale_cost,
        COUNT(*) AS sales_count,
        ARRAY[SUM(ws.ws_net_paid), SUM(ws.ws_ext_wholesale_cost)] AS agg_metrics
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_country IN ('HUNGARY', 'KOREA', 'MOZAMBIQUE')
      AND c.c_salutation = 'Mr.'
      AND ws.ws_ext_wholesale_cost > 1000
      AND ws.ws_web_site_sk IN (21, 25, 33)
      AND ib.ib_lower_bound >= 20000
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        c.c_birth_country,
        c.c_salutation,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    s.c_customer_sk,
    s.c_first_name,
    s.c_last_name,
    s.c_email_address,
    s.c_birth_country,
    s.c_salutation,
    s.hd_demo_sk,
    s.hd_income_band_sk,
    s.ib_lower_bound,
    s.ib_upper_bound,
    s.total_net_paid,
    s.total_wholesale_cost,
    s.sales_count,
    CASE
        WHEN s.total_net_paid > 50000 THEN 'HIGH'
        WHEN s.total_net_paid > 20000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS spend_category,
    RANK() OVER (PARTITION BY s.hd_income_band_sk ORDER BY s.total_net_paid DESC) AS income_band_net_paid_rank,
    t.metric_index,
    CASE t.metric_index WHEN 1 THEN 'total_net_paid' WHEN 2 THEN 'total_wholesale_cost' END AS metric_name,
    t.metric_value
FROM sales_agg s
CROSS JOIN UNNEST(s.agg_metrics) WITH ORDINALITY AS t(metric_value, metric_index)
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT DISTINCT regexp_extract(c2.c_email_address, '@([^.]*)\\.', 1) AS domain
        FROM customer c2
        WHERE c2.c_email_address IS NOT NULL
    ) d
    WHERE d.domain = regexp_extract(s.c_email_address, '@([^.]*)\\.', 1)
)
ORDER BY s.c_birth_country, income_band_net_paid_rank, s.c_customer_sk
