WITH sampled_sales AS (
        SELECT *
        FROM store_sales TABLESAMPLE BERNOULLI (10)
    ),
    desc_expanded AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_store_sk,
            ss.ss_item_sk,
            ss.ss_net_profit,
            i.i_current_price,
            i.i_item_id,
            i.i_item_desc,
            word
        FROM sampled_sales ss
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(word)
        WHERE regexp_like(word, '^[AEIOUaeiou]')
    )
SELECT
    s.s_store_name,
    COUNT(DISTINCT de.ss_ticket_number) AS ticket_cnt,
    SUM(de.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT de.ss_item_sk) AS distinct_item_cnt,
    AVG(de.i_current_price) AS avg_item_price,
    REGEXP_EXTRACT(MIN(de.i_item_id), '[0-9]+') AS sample_item_number
FROM desc_expanded de
JOIN store s
    ON de.ss_store_sk = s.s_store_sk
WHERE s.s_store_name LIKE '%Market%'
  AND regexp_like(s.s_store_name, '^.*[A-Z].*$')
GROUP BY s.s_store_name
ORDER BY total_net_profit DESC
LIMIT 100
