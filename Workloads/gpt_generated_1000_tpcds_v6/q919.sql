WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_item_sk,
        sr.sr_addr_sk,
        sr.sr_return_amt_inc_tax,
        sr.sr_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_item_desc, '(?i)premium')
      AND ca.ca_county LIKE 'M%'
)
SELECT
    s.s_store_name,
    r.r_reason_desc,
    regexp_extract(i.i_item_desc, '^([^ ]+)', 1) AS first_word,
    CONCAT(s.s_store_name, ' - ', r.r_reason_desc) AS store_reason_label,
    COUNT(*) AS return_cnt,
    SUM(fr.sr_return_amt_inc_tax) AS total_return_inc_tax,
    SUM(fr.sr_net_loss) AS total_net_loss
FROM filtered_returns fr
JOIN store s ON fr.sr_store_sk = s.s_store_sk
JOIN reason r ON fr.sr_reason_sk = r.r_reason_sk
JOIN item i ON fr.sr_item_sk = i.i_item_sk
GROUP BY
    s.s_store_name,
    r.r_reason_desc,
    regexp_extract(i.i_item_desc, '^([^ ]+)', 1),
    CONCAT(s.s_store_name, ' - ', r.r_reason_desc)
ORDER BY total_return_inc_tax DESC
LIMIT 100
