WITH filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_item_desc
    FROM item
    WHERE regexp_like(i_product_name, '\\d{2}')
      AND i_item_desc LIKE '%large%'
)
SELECT
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    r.r_reason_desc,
    COUNT(*) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    substr(s.s_store_name, 1, 5) AS store_name_prefix
FROM filtered_items i
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN reason r
    ON r.r_reason_sk = sr.sr_reason_sk
WHERE s.s_store_name LIKE '%Park%'
  AND regexp_like(r.r_reason_desc, '(damaged|defective)')
GROUP BY
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state),
    r.r_reason_desc,
    substr(s.s_store_name, 1, 5)
ORDER BY total_return_amount DESC
LIMIT 100
