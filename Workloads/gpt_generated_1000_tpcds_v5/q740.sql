WITH filtered_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_promo_sk,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        i.i_category,
        i.i_item_desc,
        s.s_city,
        s.s_state,
        s.s_store_name,
        p.p_discount_active
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(i.i_item_desc, '\\d{3}-[A-Z]+')
      AND s.s_store_name LIKE '%Market%'
)
SELECT
    s_city,
    s_state,
    CONCAT(s_city, ', ', s_state) AS location,
    i_category,
    REGEXP_EXTRACT(i_item_desc, '^([^ ]+)') AS first_word_desc,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_profit) AS total_profit,
    AVG(ss_ext_discount_amt) AS avg_discount,
    SUM(CASE WHEN p_discount_active = 'Y' THEN ss_net_profit ELSE 0 END) AS promo_profit
FROM filtered_sales
GROUP BY
    s_city,
    s_state,
    i_category,
    REGEXP_EXTRACT(i_item_desc, '^([^ ]+)')
ORDER BY total_profit DESC
LIMIT 100
