WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_reason_sk,
        r.r_reason_desc
    FROM store_returns sr
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|break|crack')
      AND sr.sr_return_quantity > 0
)
SELECT
    s.s_store_id,
    concat(s.s_city, ', ', s.s_state) AS location,
    substring(s.s_zip, 1, 5) AS zip_prefix,
    fr.r_reason_desc,
    regexp_extract(fr.r_reason_desc, 'because ([A-Za-z]+)', 1) AS cause_word,
    COUNT(DISTINCT fr.sr_ticket_number) AS return_count,
    SUM(fr.sr_net_loss) AS total_net_loss,
    AVG(ss.ss_net_profit) AS avg_store_sales_profit
FROM filtered_returns fr
JOIN store s
    ON fr.sr_store_sk = s.s_store_sk
JOIN store_sales ss
    ON fr.sr_ticket_number = ss.ss_ticket_number
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
WHERE s.s_city LIKE 'A%'
GROUP BY
    s.s_store_id,
    concat(s.s_city, ', ', s.s_state),
    substring(s.s_zip, 1, 5),
    fr.r_reason_desc,
    regexp_extract(fr.r_reason_desc, 'because ([A-Za-z]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
