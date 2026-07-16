WITH cc AS (
   SELECT
     cc_call_center_sk,
     cc_name,
     concat(trim(cc_city), ', ', trim(cc_state)) AS city_state,
     lower(cc_manager) AS manager_lower,
     regexp_replace(cc_hours, '[:\\-]', '') AS hours_numeric_str,
     regexp_extract(cc_hours, '(\\d{1,2}:\\d{2})', 1) AS start_time,
     regexp_extract(cc_hours, '-\\s*(\\d{1,2}:\\d{2})', 1) AS end_time,
     length(cc_name) AS name_len,
     replace(cc_name, ' ', '_') AS name_underscored
   FROM call_center
),
i AS (
   SELECT
     i_item_sk,
     i_item_id,
     i_product_name,
     i_item_desc,
     i_brand,
     i_category,
     lower(i_product_name) AS prod_name_lower,
     replace(i_product_name, ' ', '-') AS prod_name_dash,
     substr(i_item_id, 1, 4) AS item_id_prefix,
     length(i_item_desc) AS desc_len,
     regexp_replace(lower(i_item_desc), '[^a-z0-9 ]', '') AS clean_desc,
     regexp_like(i_item_desc, '(?i)organic') AS has_organic
   FROM item
),
i_words AS (
   SELECT
     i_item_sk,
     i_item_desc,
     split(i_item_desc, ' ') AS words
   FROM i
),
i_exploded AS (
   SELECT
     i_item_sk,
     i_item_desc,
     word,
     length(word) AS word_len
   FROM i_words
   CROSS JOIN UNNEST(words) AS t (word)
),
i_word_stats AS (
   SELECT
     i_item_sk,
     i_item_desc,
     count(*) AS word_cnt,
     max(word_len) AS max_word_len,
     slice(array_agg(word ORDER BY word_len DESC), 1, 5) AS top5_words
   FROM i_exploded
   GROUP BY i_item_sk, i_item_desc
),
wp AS (
   SELECT
     wp_web_page_sk,
     wp_url,
     lower(wp_url) AS url_lower,
     regexp_replace(wp_url, '^https?://', '') AS url_no_proto,
     split(regexp_replace(wp_url, '^https?://', ''), '/') AS url_parts,
     element_at(split(regexp_replace(wp_url, '^https?://', ''), '/'), 1) AS domain,
     length(wp_url) AS url_len,
     regexp_like(lower(wp_url), 'sale') AS contains_sale,
     replace(wp_url, '/', '_') AS url_underscored
   FROM web_page
)
SELECT
   cc.cc_call_center_sk,
   cc.city_state,
   cc.manager_lower,
   cc.start_time,
   cc.end_time,
   cc.name_len,
   cc.name_underscored,
   i.i_item_sk,
   i.item_id_prefix,
   i.prod_name_lower,
   i.prod_name_dash,
   i.desc_len,
   i.clean_desc,
   i.has_organic,
   ws.word_cnt,
   ws.max_word_len,
   ws.top5_words,
   wp.domain,
   wp.contains_sale,
   concat_ws('_', cc.name_underscored, i.item_id_prefix, wp.domain) AS composite_key,
   substring(i.prod_name_lower, 1, 10) AS prod_name_prefix,
   upper(i.i_brand) AS brand_upper,
   length(wp.url_lower) AS url_len_lower
FROM cc
JOIN i ON (i.i_item_sk % 1000) = (cc.cc_call_center_sk % 1000)
JOIN i_word_stats ws ON ws.i_item_sk = i.i_item_sk
JOIN wp ON (wp.wp_web_page_sk % 500) = (cc.cc_call_center_sk % 500)
WHERE cc.name_len > 5
  AND ws.word_cnt > 3
  AND wp.contains_sale
ORDER BY ws.max_word_len DESC, cc.cc_call_center_sk
LIMIT 100
