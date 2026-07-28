WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_return_time_sk,
        sr.sr_net_loss,
        sr.sr_ticket_number
    FROM store_returns sr
    WHERE NOT EXISTS (
        SELECT 1
        FROM time_dim t_ex
        WHERE t_ex.t_time_sk = sr.sr_return_time_sk
          AND t_ex.t_minute = 10
    )
)
SELECT
    s.s_store_id,
    s.s_store_name,
    regexp_extract(r.r_reason_desc, '^([^ ]+)', 1) AS reason_first_word,
    SUM(fr.sr_net_loss) AS total_net_loss,
    COUNT(fr.sr_ticket_number) AS return_count,
    CASE
        WHEN SUM(fr.sr_net_loss) > 10000 THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM filtered_returns fr
JOIN store s
    ON fr.sr_store_sk = s.s_store_sk
JOIN reason r
    ON fr.sr_reason_sk = r.r_reason_sk
JOIN time_dim t
    ON fr.sr_return_time_sk = t.t_time_sk
WHERE regexp_like(r.r_reason_desc, '(?i)price')
  AND s.s_store_name LIKE '%Store%'
  AND CONCAT(s.s_state, '-', s.s_zip) LIKE 'CA-%'
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_store_sk = s.s_store_sk
          AND r2.r_reason_desc = 'Did not like the model'
  )
GROUP BY
    s.s_store_id,
    s.s_store_name,
    regexp_extract(r.r_reason_desc, '^([^ ]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
