WITH avg_qty AS (
    SELECT avg(cs_quantity) AS avg_qty
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk BETWEEN 2450800 AND 2451200
)
SELECT
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_street_number, ' ', s.s_street_name, ', ', s.s_city, ' ', s.s_state) AS store_full_address,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS txn_count,
    AVG(ss.ss_net_profit) AS avg_profit_per_txn,
    REGEXP_EXTRACT(i.i_item_desc, '(?i)(promo\\w*)', 1) AS promo_word,
    CASE
        WHEN REGEXP_LIKE(i.i_item_desc, '(?i)promo') THEN 'PromoItem'
        ELSE 'RegularItem'
    END AS item_type,
    (SELECT avg_qty FROM avg_qty) AS overall_avg_qty,
    st.store_tag
FROM
    store_sales ss
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT CONCAT('Store-', s.s_store_id) AS store_tag
    ) st
WHERE
    d.d_year = 2002
    AND i.i_item_desc IS NOT NULL
    AND REGEXP_LIKE(i.i_item_desc, '(?i)promo')
    AND ss.ss_quantity > (SELECT avg_qty FROM avg_qty)
    AND s.s_suite_number LIKE 'Suite %'
    AND CONCAT(i.i_color, '-', i.i_size) LIKE '%-M%'
GROUP BY
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_street_number, ' ', s.s_street_name, ', ', s.s_city, ' ', s.s_state),
    REGEXP_EXTRACT(i.i_item_desc, '(?i)(promo\\w*)', 1),
    CASE
        WHEN REGEXP_LIKE(i.i_item_desc, '(?i)promo') THEN 'PromoItem'
        ELSE 'RegularItem'
    END,
    st.store_tag,
    (SELECT avg_qty FROM avg_qty)
ORDER BY
    total_net_profit DESC
OFFSET 10
LIMIT 100
