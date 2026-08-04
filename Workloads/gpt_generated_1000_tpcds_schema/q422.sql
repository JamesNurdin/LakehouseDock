WITH
store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS store_profit_sign
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND regexp_like(i.i_item_desc, '^.*[A-Z]{3}.*$')
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS web_profit_sign
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_item_desc LIKE '%widget%'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category
),
promo_words AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        word
    FROM promotion p
    CROSS JOIN UNNEST(split(p.p_promo_name, ' ')) AS t(word)
),
item_promo AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        pw.word,
        COUNT(*) AS promo_word_cnt
    FROM item i
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN promo_words pw ON pw.p_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_sk, i.i_item_id, pw.word
),
excluded_items AS (
    SELECT i_item_id
    FROM store_agg
    EXCEPT
    SELECT i_item_id
    FROM web_agg
),
full_sales AS (
    SELECT
        COALESCE(s.i_item_sk, w.i_item_sk) AS i_item_sk,
        COALESCE(s.i_item_id, w.i_item_id) AS i_item_id,
        COALESCE(s.i_category, w.i_category) AS i_category,
        s.store_net_profit,
        s.store_quantity,
        s.store_profit_sign,
        w.web_net_profit,
        w.web_quantity,
        w.web_profit_sign
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.i_item_sk = w.i_item_sk
)
SELECT
    f.i_item_id,
    f.i_category,
    f.store_net_profit,
    f.web_net_profit,
    CASE
        WHEN f.store_net_profit > f.web_net_profit THEN 'STORE_BETTER'
        WHEN f.store_net_profit < f.web_net_profit THEN 'WEB_BETTER'
        ELSE 'EQUAL'
    END AS better_channel,
    pw.word,
    pw.promo_word_cnt,
    CASE WHEN ei.i_item_id IS NOT NULL THEN TRUE ELSE FALSE END AS store_only_flag
FROM full_sales f
LEFT JOIN item_promo pw ON pw.i_item_sk = f.i_item_sk
LEFT JOIN excluded_items ei ON ei.i_item_id = f.i_item_id
WHERE f.store_quantity IS NOT NULL
   OR f.web_quantity IS NOT NULL
ORDER BY f.i_item_id
LIMIT 100
