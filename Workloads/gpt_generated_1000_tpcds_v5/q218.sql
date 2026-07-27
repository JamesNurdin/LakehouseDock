WITH store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_street_number,
        s.s_street_name,
        s.s_city,
        s.s_state,
        CONCAT(s.s_street_number, ' ', s.s_street_name, ', ', s.s_city, ', ', s.s_state) AS full_address,
        REGEXP_EXTRACT(s.s_street_number, '(\\d+)', 1) AS street_number_extracted,
        CASE
            WHEN s.s_floor_space >= 20000 THEN 'Large'
            WHEN s.s_floor_space >= 10000 THEN 'Medium'
            ELSE 'Small'
        END AS store_size_category,
        s.s_gmt_offset
    FROM store s
    WHERE REGEXP_LIKE(s.s_street_name, '(?i)6th|Sixth')
      AND s.s_city LIKE '%York%'
)
SELECT
    si.s_store_sk,
    si.full_address,
    si.store_size_category,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_ticket_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_return_tax) AS avg_return_tax,
    CASE WHEN SUM(sr.sr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_level,
    (
        SELECT MAX(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = si.s_store_sk
    ) AS max_return_amount,
    si.s_gmt_offset
FROM store_info si
JOIN store_returns sr
    ON sr.sr_store_sk = si.s_store_sk
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_store_sk = si.s_store_sk
          AND sr3.sr_reversed_charge > 1000
    )
GROUP BY
    si.s_store_sk,
    si.full_address,
    si.store_size_category,
    si.s_gmt_offset
HAVING SUM(sr.sr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
