SELECT
    ib.ib_income_band_sk,
    CONCAT('Band ', CAST(ib.ib_lower_bound AS VARCHAR), '-', CAST(ib.ib_upper_bound AS VARCHAR)) AS income_band_range,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_fee) AS avg_fee
FROM customer c
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
CROSS JOIN LATERAL (
    SELECT
        regexp_extract(c.c_email_address, '@(.+)$', 1) AS email_domain,
        regexp_extract(c.c_email_address, '^([^@]+)', 1) AS email_user
) AS e
WHERE e.email_domain = 'example.com'
  AND c.c_login LIKE 'user_%'
  AND e.email_user LIKE '%admin%'
GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
HAVING SUM(wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
