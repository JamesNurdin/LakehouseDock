WITH store_returns_joined AS (
    SELECT
        sr.sr_ticket_number AS ticket_number,
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_return_amt AS return_amt,
        sr.sr_store_sk AS store_sk,
        s.s_store_id AS s_id,
        s.s_store_name AS s_name,
        s.s_city AS s_city,
        d_ret.d_date AS return_date
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE s.s_city LIKE '%York%'
      AND regexp_like(s.s_store_name, '^\\w+')
)
SELECT
    s_id,
    s_city,
    COUNT(DISTINCT ticket_number) AS num_returns,
    SUM(return_amt) AS total_return_amount,
    regexp_extract(s_name, '^\\w+', 0) AS store_name_first_word,
    (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2) AS avg_return_amount_all_stores
FROM store_returns_joined srj
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end   ON p.p_end_date_sk = d_end.d_date_sk
    WHERE d_start.d_date <= srj.return_date
      AND d_end.d_date   >= srj.return_date
      AND p.p_channel_email = 'Y'
)
GROUP BY s_id, s_city, s_name
ORDER BY total_return_amount DESC
LIMIT 100
