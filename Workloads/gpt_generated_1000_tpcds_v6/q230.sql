WITH returns_by_store AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_addr_sk,
        SUM(sr.sr_refunded_cash) AS total_refunded,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_addr_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_division_id,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    ca.ca_location_type,
    rb.total_refunded,
    rb.total_net_loss,
    rb.return_cnt,
    REGEXP_EXTRACT(s.s_street_name, '(\\d+)[a-z]*', 1) AS street_number_extracted,
    CASE
        WHEN REGEXP_LIKE(ca.ca_address_id, '^AAAAAAA[AE].*') THEN 'PatternA'
        ELSE 'Other'
    END AS address_pattern_category
FROM returns_by_store rb
JOIN store s
    ON rb.sr_store_sk = s.s_store_sk
JOIN customer_address ca
    ON rb.sr_addr_sk = ca.ca_address_sk
WHERE
    s.s_division_id = 1
    AND REGEXP_LIKE(s.s_street_name, '^12')
    AND ca.ca_location_type LIKE '%family%'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND sr2.sr_refunded_cash > 1000
          AND sr2.sr_fee < 50
    )
ORDER BY rb.total_refunded DESC
LIMIT 100
