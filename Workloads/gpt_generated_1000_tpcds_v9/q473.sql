WITH cr_full AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_refunded_customer_sk,
        d.d_year,
        d.d_date
    FROM catalog_returns cr
    FULL OUTER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
),
first_set AS (
    SELECT
        CAST('CR' AS varchar) AS source,
        cf.d_year,
        SUM(cf.cr_return_amount) AS metric_val,
        COUNT(cf.cr_return_quantity) AS metric_cnt,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1) AS extra_text,
        CASE WHEN c.c_email_address IS NOT NULL AND REGEXP_LIKE(c.c_email_address, '^.*@example\\.com$') THEN 1 ELSE 0 END AS flag
    FROM cr_full cf
    LEFT JOIN customer c
        ON cf.cr_refunded_customer_sk = c.c_customer_sk
    WHERE (cf.d_year = 2001 OR cf.d_year IS NULL)
      AND (c.c_email_address IS NULL OR REGEXP_LIKE(c.c_email_address, '^.*@.*\\.com$'))
      AND (c.c_first_name IS NULL OR c.c_first_name LIKE 'A%')
    GROUP BY cf.d_year,
        REGEXP_EXTRACT(c.c_email_address, '@(.+)$', 1),
        CASE WHEN c.c_email_address IS NOT NULL AND REGEXP_LIKE(c.c_email_address, '^.*@example\\.com$') THEN 1 ELSE 0 END
),
second_set AS (
    SELECT
        CAST('WS' AS varchar) AS source,
        d.d_year,
        SUM(ws.ws_net_profit) AS metric_val,
        COUNT(*) AS metric_cnt,
        CONCAT(sm.sm_type, ':', sm.sm_carrier) AS extra_text,
        CASE WHEN REGEXP_LIKE(sm.sm_carrier, '^FedEx.*') THEN 1 ELSE 0 END AS flag
    FROM web_sales ws
    LEFT JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE (d.d_year = 2001 OR d.d_year IS NULL)
      AND (sm.sm_carrier IS NULL OR sm.sm_carrier LIKE 'Fed%')
    GROUP BY d.d_year,
        CONCAT(sm.sm_type, ':', sm.sm_carrier),
        CASE WHEN REGEXP_LIKE(sm.sm_carrier, '^FedEx.*') THEN 1 ELSE 0 END
)
SELECT *
FROM (
    SELECT * FROM first_set
    UNION ALL
    SELECT * FROM second_set
) AS combined
ORDER BY d_year DESC, metric_val DESC
LIMIT 100
