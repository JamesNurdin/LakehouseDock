WITH item_processed AS (
 SELECT i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        trim(i.i_product_name) AS trimmed_name,
        regexp_replace(i.i_product_name, '[0-9]', '') AS name_no_digits,
        upper(i.i_product_name) AS name_upper,
        CASE WHEN strpos(i.i_product_name, ' ') > 0 THEN true ELSE false END AS name_has_space,
        replace(i.i_product_name, '-', ' ') AS name_replaced,
        lower(regexp_replace(i.i_product_name, '\\s+', '')) AS prod_name_nospace,
        substr(i.i_product_name, 1, 3) AS prod_name_prefix,
        regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '') AS clean_desc,
        lower(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS clean_desc_lower,
        cardinality(split(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', ''), ' ')) AS desc_word_count,
        length(i.i_item_desc) AS desc_char_len,
        i.i_category,
        i.i_color
 FROM item i
),
sales_combined AS (
 SELECT cs.cs_item_sk AS item_sk,
        sum(cs.cs_net_paid) AS total_net_paid,
        sum(cs.cs_net_profit) AS total_net_profit,
        sum(cs.cs_quantity) AS total_quantity
 FROM catalog_sales cs
 GROUP BY cs.cs_item_sk
 UNION ALL
 SELECT ss.ss_item_sk AS item_sk,
        sum(ss.ss_net_paid) AS total_net_paid,
        sum(ss.ss_net_profit) AS total_net_profit,
        sum(ss.ss_quantity) AS total_quantity
 FROM store_sales ss
 GROUP BY ss.ss_item_sk
 UNION ALL
 SELECT ws.ws_item_sk AS item_sk,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_net_profit) AS total_net_profit,
        sum(ws.ws_quantity) AS total_quantity
 FROM web_sales ws
 GROUP BY ws.ws_item_sk
),
item_sales AS (
 SELECT ip.i_item_sk,
        ip.i_item_id,
        ip.i_product_name,
        ip.trimmed_name,
        ip.name_no_digits,
        ip.name_upper,
        ip.name_has_space,
        ip.name_replaced,
        ip.prod_name_nospace,
        ip.prod_name_prefix,
        ip.clean_desc,
        ip.clean_desc_lower,
        ip.desc_word_count,
        ip.desc_char_len,
        ip.i_category,
        ip.i_color,
        coalesce(sc.total_net_paid, 0) AS total_net_paid,
        coalesce(sc.total_net_profit, 0) AS total_net_profit,
        coalesce(sc.total_quantity, 0) AS total_quantity,
        concat(ip.i_category, '-', ip.i_color, '-', ip.prod_name_prefix) AS cat_color_prefix,
        length(ip.prod_name_nospace) AS prod_name_nospace_len,
        regexp_like(ip.i_product_name, '^.*[0-9].*$') AS prod_name_contains_digit,
        regexp_extract(ip.i_product_name, '([A-Za-z]+)', 1) AS first_alpha_seq,
        reverse(ip.prod_name_nospace) AS rev_prod_name_nospace
 FROM item_processed ip
 LEFT JOIN sales_combined sc ON ip.i_item_sk = sc.item_sk
)
SELECT i.i_item_sk,
       i.i_item_id,
       i.i_product_name,
       i.trimmed_name,
       i.name_upper,
       i.name_has_space,
       i.name_replaced,
       i.total_net_paid,
       i.total_net_profit,
       i.total_quantity,
       i.desc_word_count,
       i.desc_char_len,
       i.prod_name_prefix,
       i.cat_color_prefix,
       i.prod_name_nospace,
       i.prod_name_nospace_len,
       i.rev_prod_name_nospace,
       i.first_alpha_seq,
       i.prod_name_contains_digit,
       (i.total_net_paid / nullif(i.total_quantity, 0)) *
       (i.desc_word_count + i.prod_name_nospace_len) *
       (CASE WHEN i.prod_name_contains_digit THEN 2 ELSE 1 END) AS weighted_score
FROM item_sales i
WHERE i.total_net_paid > 0
  AND regexp_like(i.i_product_name, '^.*[A-Z].*$')
ORDER BY weighted_score DESC
LIMIT 20
