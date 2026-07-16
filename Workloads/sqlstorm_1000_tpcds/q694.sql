WITH unified_sales AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        i.i_brand AS brand,
        NULL AS store_name,
        p.p_promo_name AS promo_name,
        i.i_product_name AS product_name,
        i.i_item_id AS item_id,
        NULL AS url,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_price
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk

    UNION ALL

    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        i.i_brand AS brand,
        s.s_store_name AS store_name,
        p.p_promo_name AS promo_name,
        i.i_product_name AS product_name,
        i.i_item_id AS item_id,
        NULL AS url,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_price
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk

    UNION ALL

    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        i.i_brand AS brand,
        NULL AS store_name,
        p.p_promo_name AS promo_name,
        i.i_product_name AS product_name,
        i.i_item_id AS item_id,
        wp.wp_url AS url,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales_price
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
)

SELECT
    brand,
    COUNT(*) AS order_cnt,
    SUM(quantity) AS total_qty,
    SUM(sales_price) AS total_sales,
    AVG(product_name_len) AS avg_name_len,
    AVG(cleaned_name_len) AS avg_clean_name_len,
    AVG(special_char_count) AS avg_special_chars,
    AVG(e_char_count) AS avg_e_char_count,
    SUM(promo_flag_discount) AS discount_promo_cnt,
    COUNT(DISTINCT numeric_item_id) AS distinct_item_numbers,
    COUNT(DISTINCT domain_extracted) AS distinct_domains,
    MAX(domain_extracted) AS max_domain,
    MIN(domain_extracted) AS min_domain,
    approx_percentile(CAST(product_name_len AS double), 0.5) AS median_name_len,
    MIN(CASE WHEN vowel_check = 'HasVowel' THEN sales_price END) AS min_vowel_sales_price,
    MAX(CASE WHEN vowel_check = 'HasVowel' THEN sales_price END) AS max_vowel_sales_price,
    SUM(CASE WHEN lower(product_name) LIKE '%special%' THEN quantity END) AS special_product_qty
FROM (
    SELECT
        brand,
        store_name,
        promo_name,
        product_name,
        item_id,
        url,
        quantity,
        sales_price,
        length(product_name) AS product_name_len,
        length(regexp_replace(product_name, '[^A-Za-z0-9]', '')) AS cleaned_name_len,
        length(regexp_replace(product_name, '[A-Za-z0-9]', '')) AS special_char_count,
        lower(product_name) AS product_name_lower,
        upper(product_name) AS product_name_upper,
        substr(product_name, 1, 5) AS product_name_prefix,
        substr(product_name, -5) AS product_name_suffix,
        replace(product_name, ' ', '_') AS product_name_underscored,
        strpos(product_name, 'e') AS first_e_pos,
        length(product_name) - length(replace(product_name, 'e', '')) AS e_char_count,
        reverse(product_name) AS product_name_reverse,
        CASE WHEN lower(promo_name) LIKE '%discount%' THEN 1 ELSE 0 END AS promo_flag_discount,
        regexp_extract(item_id, '\\d+', 0) AS numeric_item_id,
        CASE WHEN url IS NOT NULL THEN regexp_extract(url, 'https?://([^/]+)/', 1) END AS domain_extracted,
        CASE WHEN regexp_like(product_name, '[AEIOUaeiou]') THEN 'HasVowel' ELSE 'NoVowel' END AS vowel_check
    FROM unified_sales
) AS s
GROUP BY brand
ORDER BY total_sales DESC
LIMIT 100
