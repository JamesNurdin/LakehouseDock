WITH desc_words AS (
    SELECT
        cc.cc_call_center_id AS cc_id,
        lower(regexp_replace(i.i_item_desc, '[^a-z0-9 ]', '')) AS clean_desc
    FROM call_center cc
    JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cc.cc_rec_end_date > DATE '2024-10-01' - INTERVAL '365' DAY
),
word_counts AS (
    SELECT
        cc_id,
        word,
        count(*) AS cnt
    FROM desc_words
    CROSS JOIN UNNEST(split(clean_desc, ' ')) AS t(word)
    WHERE word <> ''
    GROUP BY cc_id, word
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    length(cc.cc_name) AS name_len,
    regexp_replace(lower(cc.cc_name), '[^a-z]', '') AS normalized_name,
    length(regexp_replace(lower(cc.cc_name), '[^a-z]', '')) AS normalized_len,
    concat_ws('|', cc.cc_manager, cc.cc_market_manager) AS manager_combo,
    sum(cs.cs_net_profit) AS total_net_profit,
    count(DISTINCT cs.cs_order_number) AS total_orders,
    array_join(array_agg(DISTINCT i.i_item_desc), '||') AS aggregated_item_descs,
    avg(length(i.i_product_name)) AS avg_product_name_len,
    (
        SELECT array_join(slice(array_agg(word ORDER BY cnt DESC), 1, 5), ', ')
        FROM word_counts wc2
        WHERE wc2.cc_id = cc.cc_call_center_id
    ) AS top_5_desc_words,
    (
        SELECT count(DISTINCT word)
        FROM word_counts wc2
        WHERE wc2.cc_id = cc.cc_call_center_id
    ) AS unique_word_count,
    cardinality(split(cc.cc_hours, ':')) AS hour_parts,
    replace(cc.cc_hours, ':', '-') AS hours_dash,
    count(DISTINCT CASE WHEN regexp_like(s.s_store_name, '\\d') THEN s.s_store_name END) AS stores_with_digit
FROM call_center cc
JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
LEFT JOIN store_sales ss ON cs.cs_order_number = ss.ss_ticket_number
LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
WHERE cc.cc_rec_end_date > DATE '2024-10-01' - INTERVAL '365' DAY
GROUP BY
    cc.cc_call_center_id,
    cc.cc_name,
    length(cc.cc_name),
    regexp_replace(lower(cc.cc_name), '[^a-z]', ''),
    length(regexp_replace(lower(cc.cc_name), '[^a-z]', '')),
    concat_ws('|', cc.cc_manager, cc.cc_market_manager),
    cc.cc_hours,
    cc.cc_manager,
    cc.cc_market_manager,
    cardinality(split(cc.cc_hours, ':')),
    replace(cc.cc_hours, ':', '-')
ORDER BY total_net_profit DESC
LIMIT 20
