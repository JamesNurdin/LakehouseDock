WITH filtered_returns AS (
    SELECT
        sr.sr_reason_sk,
        sr.sr_item_sk,
        sr.sr_net_loss,
        i.i_product_name,
        r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)damage|warranty')
)
SELECT
    r_reason_desc,
    regexp_extract(r_reason_desc, '^([A-Za-z]+)', 1) AS first_word,
    SUM(sr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr_item_sk) AS distinct_items_returned,
    SUM(CASE WHEN i_product_name LIKE '%Premium%' THEN 1 ELSE 0 END) AS premium_item_returns
FROM filtered_returns
GROUP BY
    r_reason_desc,
    regexp_extract(r_reason_desc, '^([A-Za-z]+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
