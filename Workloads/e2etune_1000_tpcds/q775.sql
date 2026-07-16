WITH date_range AS (
    SELECT cp_start_date_sk AS start_sk, cp_end_date_sk AS end_sk
    FROM catalog_page
    WHERE cp_catalog_page_id = 'AAAAAAAABAAAAAAA'
    LIMIT 1
),
unified_returns AS (
    SELECT
        sr.sr_customer_sk AS customer_sk,
        sr.sr_addr_sk AS address_sk,
        sr.sr_hdemo_sk AS hd_demo_sk,
        sr.sr_net_loss AS net_loss,
        sr.sr_returned_date_sk AS returned_date_sk,
        'store' AS return_source
    FROM store_returns sr
    UNION ALL
    SELECT
        wr.wr_refunded_customer_sk AS customer_sk,
        wr.wr_refunded_addr_sk AS address_sk,
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        wr.wr_net_loss AS net_loss,
        wr.wr_returned_date_sk AS returned_date_sk,
        'web' AS return_source
    FROM web_returns wr
)
SELECT
    ca.ca_state AS state,
    hd.hd_income_band_sk AS income_band,
    COUNT(DISTINCT ur.customer_sk) AS unique_customers,
    SUM(CASE WHEN ur.return_source = 'store' THEN ur.net_loss ELSE 0 END) AS total_store_net_loss,
    SUM(CASE WHEN ur.return_source = 'web' THEN ur.net_loss ELSE 0 END) AS total_web_net_loss,
    SUM(ur.net_loss) AS total_combined_net_loss,
    AVG(c.c_birth_year) AS avg_birth_year
FROM unified_returns ur
JOIN date_range dr ON ur.returned_date_sk BETWEEN dr.start_sk AND dr.end_sk
JOIN customer c ON ur.customer_sk = c.c_customer_sk
JOIN household_demographics hd ON ur.hd_demo_sk = hd.hd_demo_sk
JOIN customer_address ca ON ur.address_sk = ca.ca_address_sk
WHERE c.c_birth_year >= 1990
  AND ca.ca_state IS NOT NULL
GROUP BY ca.ca_state, hd.hd_income_band_sk
HAVING SUM(ur.net_loss) > 5000
ORDER BY total_combined_net_loss DESC
LIMIT 10
