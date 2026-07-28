WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_ticket_number,
        sr.sr_net_loss,
        d.d_year,
        d.d_month_seq
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)
SELECT
    r.r_reason_desc,
    regexp_extract(i.i_item_desc, '([A-Za-z]+)\\s', 1) AS first_word,
    SUM(fr.sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT fr.sr_ticket_number) AS return_count
FROM filtered_returns fr
JOIN store_sales ss
    ON fr.sr_ticket_number = ss.ss_ticket_number
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN reason r
    ON fr.sr_reason_sk = r.r_reason_sk
WHERE regexp_like(r.r_reason_desc, '(?i)size')
  AND i.i_item_desc LIKE '%blue%'
GROUP BY r.r_reason_desc,
         regexp_extract(i.i_item_desc, '([A-Za-z]+)\\s', 1)
HAVING SUM(fr.sr_net_loss) > 5000
ORDER BY total_net_loss DESC
LIMIT 100
