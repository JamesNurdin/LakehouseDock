WITH cs_data AS (
  SELECT
    c.cc_call_center_id,
    c.cc_name,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    COALESCE(p.p_promo_name, 'N/A') AS promo_name,
    cs.cs_quantity,
    cs.cs_sold_date_sk,
    LOWER(TRIM(i.i_product_name)) AS low_prod_name,
    REGEXP_REPLACE(i.i_item_desc, '[^A-Za-z0-9 ]', '') AS alnum_desc,
    SUBSTR(i.i_item_desc, 1, 20) AS short_desc,
    LENGTH(i.i_item_desc) AS desc_len,
    CARDINALITY(SPLIT(i.i_item_desc, ' ')) AS desc_word_cnt,
    CONCAT_WS(' | ', c.cc_name, i.i_product_name, COALESCE(p.p_promo_name, '')) AS combined_str,
    ROW_NUMBER() OVER (PARTITION BY c.cc_call_center_id ORDER BY cs.cs_sold_date_sk DESC) AS rn
  FROM catalog_sales cs
  JOIN call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE cs.cs_quantity > 0
),
ss_data AS (
  SELECT
    s.s_store_id,
    s.s_store_name,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    ss.ss_quantity,
    ss.ss_sold_date_sk,
    UPPER(TRIM(s.s_city)) AS store_city_upper,
    LOWER(TRIM(i.i_color)) AS item_color_lower,
    REGEXP_REPLACE(s.s_hours, '[^0-9:]', '') AS hours_numeric,
    CONCAT_WS('->', s.s_store_name, i.i_product_name) AS store_prod_concat,
    LENGTH(i.i_item_desc) AS desc_len,
    CARDINALITY(SPLIT(i.i_item_desc, ' ')) AS desc_word_cnt,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_sold_date_sk DESC) AS rn
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE ss.ss_quantity > 0
),
ws_data AS (
  SELECT
    wp.wp_web_page_id,
    wp.wp_url,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    ws.ws_quantity,
    ws.ws_sold_date_sk,
    REGEXP_REPLACE(wp.wp_url, '^https?://', '') AS url_no_proto,
    REPLACE(LOWER(wp.wp_type), ' ', '_') AS type_underscored,
    SUBSTR(i.i_product_name, 1, 10) AS prod_name_prefix,
    CONCAT_WS('##', wp.wp_url, i.i_product_name) AS url_prod_concat,
    LENGTH(i.i_item_desc) AS desc_len,
    CARDINALITY(SPLIT(i.i_item_desc, ' ')) AS desc_word_cnt,
    ROW_NUMBER() OVER (PARTITION BY wp.wp_web_page_id ORDER BY ws.ws_sold_date_sk DESC) AS rn
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE ws.ws_quantity > 0
)
SELECT source, identifier, benchmark_str, total_qty, avg_desc_len, avg_word_cnt, top_promos
FROM (
  SELECT
    'catalog' AS source,
    cc_call_center_id AS identifier,
    combined_str AS benchmark_str,
    SUM(cs_quantity) OVER (PARTITION BY cc_call_center_id) AS total_qty,
    AVG(desc_len) OVER (PARTITION BY cc_call_center_id) AS avg_desc_len,
    AVG(desc_word_cnt) OVER (PARTITION BY cc_call_center_id) AS avg_word_cnt,
    ARRAY_JOIN(ARRAY_AGG(DISTINCT promo_name) OVER (PARTITION BY cc_call_center_id), ', ') AS top_promos
  FROM cs_data
  WHERE rn = 1
  UNION ALL
  SELECT
    'store' AS source,
    s_store_id AS identifier,
    store_prod_concat AS benchmark_str,
    SUM(ss_quantity) OVER (PARTITION BY s_store_id) AS total_qty,
    AVG(desc_len) OVER (PARTITION BY s_store_id) AS avg_desc_len,
    AVG(desc_word_cnt) OVER (PARTITION BY s_store_id) AS avg_word_cnt,
    ARRAY_JOIN(ARRAY_AGG(DISTINCT store_city_upper) OVER (PARTITION BY s_store_id), ', ') AS top_promos
  FROM ss_data
  WHERE rn = 1
  UNION ALL
  SELECT
    'web' AS source,
    wp_web_page_id AS identifier,
    url_prod_concat AS benchmark_str,
    SUM(ws_quantity) OVER (PARTITION BY wp_web_page_id) AS total_qty,
    AVG(desc_len) OVER (PARTITION BY wp_web_page_id) AS avg_desc_len,
    AVG(desc_word_cnt) OVER (PARTITION BY wp_web_page_id) AS avg_word_cnt,
    ARRAY_JOIN(ARRAY_AGG(DISTINCT type_underscored) OVER (PARTITION BY wp_web_page_id), ', ') AS top_promos
  FROM ws_data
  WHERE rn = 1
) t
