WITH store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        CONCAT(s.s_city, ', ', s.s_state) AS store_location,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
        MAX(sr.sr_returned_date_sk) AS max_return_date_sk
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%price%'
      AND regexp_like(r.r_reason_desc, '(?i)price|cost')
      AND s.s_street_type LIKE '%Avenue%'
    GROUP BY
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.store_location,
    sa.total_net_loss,
    sa.distinct_tickets,
    ROW_NUMBER() OVER (PARTITION BY SUBSTRING(sa.s_store_id FROM 1 FOR 3) ORDER BY sa.total_net_loss DESC) AS rn_by_prefix,
    (
        SELECT date_add('day', sa.max_return_date_sk, DATE '1997-01-01')
    ) AS latest_return_date,
    (
        SELECT ARRAY_AGG(DISTINCT r2.r_reason_desc)
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = sa.s_store_sk
    ) AS reason_descs
FROM store_agg sa
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr3
    JOIN reason r3 ON sr3.sr_reason_sk = r3.r_reason_sk
    WHERE sr3.sr_store_sk = sa.s_store_sk
      AND regexp_extract(r3.r_reason_desc, '(price|cost)', 1) IS NOT NULL
)
ORDER BY sa.total_net_loss DESC
LIMIT 100
