WITH filtered_dates AS (
    SELECT d_date_sk, d_year, d_month_seq
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    'Catalog' AS return_type,
    d.d_year,
    d.d_month_seq,
    sm.sm_type AS ship_mode,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'High' ELSE 'Low' END AS amount_category,
    CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category,
    (
        SELECT COUNT(DISTINCT ca_sub.ca_zip)
        FROM catalog_returns cr_sub
        JOIN date_dim d_sub ON cr_sub.cr_returned_date_sk = d_sub.d_date_sk
        JOIN customer_address ca_sub ON cr_sub.cr_refunded_addr_sk = ca_sub.ca_address_sk
        WHERE d_sub.d_year = d.d_year AND d_sub.d_month_seq = d.d_month_seq
    ) AS distinct_zip_count
FROM catalog_returns cr
JOIN filtered_dates d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
WHERE cr.cr_return_amount > 0
  AND ca.ca_zip LIKE '9%'
GROUP BY d.d_year, d.d_month_seq, sm.sm_type
UNION ALL
SELECT
    'Store' AS return_type,
    d.d_year,
    d.d_month_seq,
    CAST(NULL AS varchar) AS ship_mode,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_net_loss) AS total_net_loss,
    CASE WHEN SUM(sr.sr_return_amt) > 5000 THEN 'High' ELSE 'Low' END AS amount_category,
    CASE WHEN SUM(sr.sr_net_loss) > 10000 THEN 'HighLoss' ELSE 'LowLoss' END AS loss_category,
    (
        SELECT COUNT(DISTINCT ca_sub.ca_zip)
        FROM store_returns sr_sub
        JOIN date_dim d_sub ON sr_sub.sr_returned_date_sk = d_sub.d_date_sk
        JOIN customer_address ca_sub ON sr_sub.sr_addr_sk = ca_sub.ca_address_sk
        WHERE d_sub.d_year = d.d_year AND d_sub.d_month_seq = d.d_month_seq
    ) AS distinct_zip_count
FROM store_returns sr
JOIN filtered_dates d ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
WHERE sr.sr_return_amt > 0
  AND ca.ca_zip LIKE '9%'
GROUP BY d.d_year, d.d_month_seq
ORDER BY return_type, d_year, d_month_seq
LIMIT 100
