WITH avg_loss AS (
    SELECT avg(sr_net_loss) AS avg_net_loss
    FROM store_returns
)
SELECT
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_store_name || '-' || s.s_state AS store_label,
    regexp_extract(r.r_reason_desc, '(\\w+)', 1) AS reason_first_word,
    COALESCE(SUM(sr.sr_net_loss), 0) AS total_net_loss,
    COUNT(sr.sr_ticket_number) AS return_cnt,
    CASE
        WHEN COALESCE(SUM(sr.sr_net_loss), 0) > (SELECT avg_net_loss FROM avg_loss) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS loss_category
FROM store_returns sr
RIGHT OUTER JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
WHERE
    s.s_store_name LIKE '%Market%'
    AND (sr.sr_store_sk IS NULL OR d.d_year = 2002)
    AND (sr.sr_store_sk IS NULL OR regexp_like(r.r_reason_desc, 'color|warranty'))
GROUP BY
    s.s_store_id,
    s.s_store_name,
    s.s_state,
    s.s_store_name || '-' || s.s_state,
    regexp_extract(r.r_reason_desc, '(\\w+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
