WITH
normalized_item AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        i.i_class,
        i.i_color,
        i.i_size,
        i.i_manufact,
        i.i_item_desc,
        lower(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', ' ')) AS normalized_desc,
        length(i.i_item_desc) AS original_desc_len,
        substring(i.i_item_desc, 1, 30) AS short_desc
    FROM item i
    WHERE i.i_item_desc IS NOT NULL
),
split_words AS (
    SELECT
        ni.*,
        split(ni.normalized_desc, ' ') AS words_array,
        cardinality(split(ni.normalized_desc, ' ')) AS word_count
    FROM normalized_item ni
),
unnested_words AS (
    SELECT
        sw.i_item_sk,
        sw.i_item_id,
        sw.i_brand,
        w.word
    FROM split_words sw
    CROSS JOIN UNNEST(sw.words_array) AS w(word)
    WHERE w.word <> ''
),
word_counts AS (
    SELECT
        i_brand,
        word,
        count(DISTINCT i_item_sk) AS items_with_word,
        sum(length(word)) AS total_word_len,
        count(*) AS total_occurrences
    FROM unnested_words
    GROUP BY i_brand, word
),
top_words_per_brand AS (
    SELECT
        i_brand,
        word,
        total_occurrences,
        row_number() OVER (PARTITION BY i_brand ORDER BY total_occurrences DESC) AS rn
    FROM word_counts
),
brand_sales AS (
    SELECT
        i.i_brand,
        sum(cs.cs_ext_sales_price) AS brand_sales,
        sum(cs.cs_net_profit) AS brand_profit,
        sum(cs.cs_quantity) AS brand_quantity
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_brand
),
store_info AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        length(s.s_store_name) AS store_name_len,
        upper(s.s_store_name) AS store_name_upper,
        lower(s.s_store_name) AS store_name_lower,
        concat_ws(' ', s.s_street_number, s.s_street_name, s.s_suite_number, s.s_city, s.s_state, s.s_zip) AS full_address,
        regexp_extract(s.s_zip, '(\\d{5})', 1) AS zip5
    FROM store s
),
brand_store_sales AS (
    SELECT
        i.i_brand,
        s.s_store_sk,
        sum(ss.ss_ext_sales_price) AS sales,
        sum(ss.ss_net_profit) AS profit,
        sum(ss.ss_quantity) AS quantity
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY i.i_brand, s.s_store_sk
),
brand_best_store AS (
    SELECT
        i_brand AS brand,
        s_store_sk AS store_sk,
        sales,
        profit,
        quantity,
        row_number() OVER (PARTITION BY i_brand ORDER BY sales DESC) AS rn
    FROM brand_store_sales
),
brand_sample_product AS (
    SELECT
        i.i_brand,
        i.i_product_name,
        row_number() OVER (PARTITION BY i.i_brand ORDER BY i.i_item_sk) AS rn
    FROM item i
)

SELECT
    bs.i_brand AS brand,
    bs.brand_sales,
    bs.brand_profit,
    bs.brand_quantity,
    tw.word AS top_word,
    tw.total_occurrences AS top_word_occurrences,
    si.s_store_name AS best_store_name,
    si.store_name_len,
    si.store_name_upper,
    si.full_address AS best_store_address,
    si.zip5,
    sp.i_product_name AS sample_product_name,
    length(sp.i_product_name) AS sample_product_name_len,
    substring(sp.i_product_name, 1, 10) AS sample_product_name_prefix,
    replace(sp.i_product_name, '-', ' ') AS sample_product_name_clean,
    upper(sp.i_product_name) AS sample_product_name_upper
FROM brand_sales bs
JOIN (
    SELECT i_brand, word, total_occurrences
    FROM top_words_per_brand
    WHERE rn = 1
) tw ON tw.i_brand = bs.i_brand
JOIN (
    SELECT brand, store_sk
    FROM brand_best_store
    WHERE rn = 1
) bbs ON bbs.brand = bs.i_brand
JOIN store_info si ON si.s_store_sk = bbs.store_sk
JOIN (
    SELECT i_brand, i_product_name
    FROM brand_sample_product
    WHERE rn = 1
) sp ON sp.i_brand = bs.i_brand
ORDER BY bs.brand_sales DESC
LIMIT 20
