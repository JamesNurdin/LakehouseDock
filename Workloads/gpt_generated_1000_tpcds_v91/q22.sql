WITH promo_tokens AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_item_sk,
        -- extract all alphabetic words from the promo name as an array
        regexp_extract_all(p.p_promo_name, '[A-Za-z]+') AS name_tokens,
        -- first three characters of the promo name
        substring(p.p_promo_name FROM 1 FOR 3) AS name_prefix
    FROM promotion p
    WHERE p.p_channel_tv = 'Y'
      AND regexp_like(p.p_promo_name, '^[A-Za-z]{4,}$')
      AND p.p_promo_name LIKE '%e%'
)
SELECT
    s.s_store_name,
    pt.name_prefix,
    token AS token_word,
    concat(s.s_store_name, ' - ', pt.name_prefix) AS store_prefix,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_net_loss) AS total_net_loss,
    AVG(sr.sr_net_loss) AS avg_net_loss
FROM promo_tokens pt
CROSS JOIN UNNEST(pt.name_tokens) AS t (token)
JOIN item i ON i.i_item_sk = pt.p_item_sk
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
JOIN store s ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim d ON d.d_date_sk = sr.sr_returned_date_sk
WHERE d.d_year = 2001
GROUP BY
    s.s_store_name,
    pt.name_prefix,
    token,
    concat(s.s_store_name, ' - ', pt.name_prefix)
ORDER BY total_net_loss DESC
LIMIT 100
