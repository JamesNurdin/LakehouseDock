WITH cs_data AS (
   SELECT
      i.i_item_sk,
      i.i_product_name,
      cc.cc_name,
      CAST(NULL AS varchar) AS s_store_name,
      CAST(NULL AS varchar) AS wp_url,
      c.c_first_name,
      c.c_last_name,
      'catalog' AS source_type,
      cs.cs_ext_sales_price AS sale_amount,
      cs.cs_quantity AS quantity
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
),
ss_data AS (
   SELECT
      i.i_item_sk,
      i.i_product_name,
      CAST(NULL AS varchar) AS cc_name,
      s.s_store_name,
      CAST(NULL AS varchar) AS wp_url,
      c.c_first_name,
      c.c_last_name,
      'store' AS source_type,
      ss.ss_ext_sales_price AS sale_amount,
      ss.ss_quantity AS quantity
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN store s ON ss.ss_store_sk = s.s_store_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
),
ws_data AS (
   SELECT
      i.i_item_sk,
      i.i_product_name,
      CAST(NULL AS varchar) AS cc_name,
      CAST(NULL AS varchar) AS s_store_name,
      wp.wp_url,
      c.c_first_name,
      c.c_last_name,
      'web' AS source_type,
      ws.ws_ext_sales_price AS sale_amount,
      ws.ws_quantity AS quantity
   FROM web_sales ws
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
)
SELECT
   i_item_sk,
   i_product_name,
   LOWER(i_product_name) AS prod_name_lower,
   UPPER(i_product_name) AS prod_name_upper,
   LENGTH(i_product_name) AS prod_name_len,
   REGEXP_COUNT(i_product_name, '[aeiouAEIOU]') AS vowel_cnt,
   REVERSE(i_product_name) AS reversed_name,
   SUBSTR(i_product_name, 1, 5) AS first_five,
   CONCAT(UPPER(REPLACE(i_product_name, ' ', '_')), '_', CAST(i_item_sk AS VARCHAR)) AS norm_item_key,
   CARDINALITY(split(i_product_name, ' ')) AS prod_word_count,
   array_join(split(i_product_name, ' '), '|') AS prod_words_pipe,
   REGEXP_EXTRACT(i_product_name, '([0-9]+)', 1) AS numeric_part,
   source_type,
   CASE WHEN source_type = 'catalog' THEN cc_name
        WHEN source_type = 'store' THEN s_store_name
        WHEN source_type = 'web' THEN wp_url
   END AS dim_string_raw,
   CASE WHEN source_type = 'catalog' THEN TRIM(cc_name)
        WHEN source_type = 'store' THEN TRIM(s_store_name)
        WHEN source_type = 'web' THEN REGEXP_REPLACE(wp_url, '\\s+', '')
   END AS dim_string_clean,
   CASE WHEN source_type = 'catalog' THEN LENGTH(TRIM(cc_name))
        WHEN source_type = 'store' THEN LENGTH(TRIM(s_store_name))
        WHEN source_type = 'web' THEN LENGTH(REGEXP_REPLACE(wp_url, '\\s+', ''))
   END AS dim_string_len,
   CONCAT_WS(' ', c_first_name, c_last_name) AS customer_full_name,
   LENGTH(CONCAT_WS(' ', c_first_name, c_last_name)) AS customer_name_len,
   REGEXP_EXTRACT(COALESCE(wp_url, ''), 'https?://([^/]+)', 1) AS domain,
   format('%s-%s', i_product_name, source_type) AS formatted_key,
   sale_amount,
   quantity,
   SUM(sale_amount) OVER (PARTITION BY i_item_sk) AS total_sales_for_item,
   ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY sale_amount DESC) AS rank_by_sale
FROM (
   SELECT * FROM cs_data
   UNION ALL
   SELECT * FROM ss_data
   UNION ALL
   SELECT * FROM ws_data
) d
WHERE
   REGEXP_LIKE(i_product_name, '[A-Z]{2}[0-9]{3}')
ORDER BY
   rank_by_sale
LIMIT 200
