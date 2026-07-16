WITH all_sales AS (
   SELECT
      ss.ss_sold_date_sk AS date_sk,
      s.s_store_id AS entity_id,
      s.s_store_name AS entity_name,
      s.s_city AS entity_city,
      s.s_state AS entity_state,
      ss.ss_net_paid AS net_paid,
      i.i_product_name AS product_name,
      'store' AS source_type
   FROM store_sales ss
   JOIN store s ON s.s_store_sk = ss.ss_store_sk
   JOIN item i ON i.i_item_sk = ss.ss_item_sk

   UNION ALL

   SELECT
      cs.cs_sold_date_sk,
      cc.cc_call_center_id,
      cc.cc_name,
      cc.cc_city,
      cc.cc_state,
      cs.cs_net_paid,
      i.i_product_name,
      'call_center'
   FROM catalog_sales cs
   JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
   JOIN item i ON i.i_item_sk = cs.cs_item_sk

   UNION ALL

   SELECT
      ws.ws_sold_date_sk,
      w.web_site_id,
      w.web_name,
      w.web_city,
      w.web_state,
      ws.ws_net_paid,
      i.i_product_name,
      'web_site'
   FROM web_sales ws
   JOIN web_site w ON w.web_site_sk = ws.ws_web_site_sk
   JOIN item i ON i.i_item_sk = ws.ws_item_sk
)
SELECT
   source_type,
   entity_id,
   entity_name,
   entity_city,
   entity_state,
   sum(net_paid) AS total_net_paid,
   format('%.2f', sum(net_paid)) AS total_net_paid_formatted,
   lower(entity_name) AS name_lower,
   upper(entity_name) AS name_upper,
   trim(entity_name) AS name_trimmed,
   replace(entity_name, ' ', '_') AS name_underscored,
   regexp_extract(entity_name, '([A-Za-z]+)', 1) AS name_alpha_prefix,
   regexp_replace(entity_name, '[^A-Za-z0-9]', '') AS name_alnum,
   length(entity_name) AS name_length,
   substr(entity_name, 1, 8) AS name_prefix,
   reverse(entity_name) AS name_reversed,
   repeat(entity_name, 3) AS name_repeated,
   concat(upper(substr(entity_name, 1, 1)), lower(substr(entity_name, 2))) AS title_case_name,
   concat_ws(', ', entity_name, entity_city, entity_state) AS full_location,
   regexp_replace(concat_ws(', ', entity_city, entity_state), '\\s+', ' ') AS clean_location,
   regexp_extract(entity_city, '^([^ ]+)', 1) AS city_first_word,
   cardinality(split(entity_city, ' ')) AS city_word_count,
   strpos(entity_name, ' ') AS first_space_position,
   array_join(array_agg(DISTINCT product_name ORDER BY product_name), ', ') AS product_list
FROM all_sales
GROUP BY
   source_type,
   entity_id,
   entity_name,
   entity_city,
   entity_state
