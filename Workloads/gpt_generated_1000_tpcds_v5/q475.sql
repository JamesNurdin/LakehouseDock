WITH store_ret_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        SUM(sr.sr_return_quantity) AS total_qty,
        SUM(sr.sr_return_amt) AS total_amt,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        MIN(sr.sr_addr_sk) AS any_addr_sk
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_reason_sk
)
SELECT DISTINCT
    reason.r_reason_desc,
    store.s_store_name,
    CONCAT(store.s_street_name, ' ', store.s_street_type) AS store_street,
    ca.ca_city,
    SUBSTR(ca.ca_zip, 1, 3) AS zip_prefix,
    store_ret_agg.total_qty,
    store_ret_agg.total_amt,
    CASE
        WHEN store_ret_agg.total_amt > COALESCE((
            SELECT AVG(wr.wr_return_amt)
            FROM web_returns wr
            WHERE wr.wr_reason_sk = reason.r_reason_sk
        ), 0) THEN 'StoreHigher'
        ELSE 'WebHigherOrEqual'
    END AS amt_comparison,
    CASE
        WHEN store_ret_agg.total_qty > 100 THEN 'HighVolume'
        ELSE 'LowVolume'
    END AS volume_category
FROM store_ret_agg
JOIN store   ON store.s_store_sk   = store_ret_agg.sr_store_sk
JOIN reason  ON reason.r_reason_sk = store_ret_agg.sr_reason_sk
JOIN customer_address ca ON ca.ca_address_sk = store_ret_agg.any_addr_sk
WHERE
    REGEXP_LIKE(reason.r_reason_desc, '(?i)service|warranty')
    AND store.s_street_type LIKE 'Dr.%'
    AND ca.ca_city LIKE 'A%'
ORDER BY
    store_ret_agg.total_amt DESC,
    reason.r_reason_desc
LIMIT 100
