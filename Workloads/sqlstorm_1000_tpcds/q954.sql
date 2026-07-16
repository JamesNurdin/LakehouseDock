WITH sales_facts AS (
   SELECT
       cs.cs_order_number,
       cs.cs_quantity,
       cs.cs_net_paid,
       i.i_product_name,
       i.i_color,
       i.i_size,
       i.i_brand,
       i.i_manufact,
       c.c_first_name,
       c.c_last_name,
       c.c_email_address,
       ca.ca_street_number,
       ca.ca_street_name,
       ca.ca_city,
       ca.ca_state,
       ca.ca_zip,
       cc.cc_name,
       cc.cc_manager,
       p.p_promo_name,
       d.d_date
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
)
SELECT
   s.*,
   row_number() OVER (ORDER BY s.order_total_net_paid DESC) AS rank_by_order_net
FROM (
   SELECT
      cs_order_number,
      substring(i_product_name, 1, 15) AS prod_name_prefix,
      regexp_replace(i_product_name, '\\s+', '_') AS prod_name_uscore,
      lower(regexp_replace(i_product_name, '[^a-z0-9]', '')) AS prod_name_clean,
      length(i_product_name) AS prod_name_len,
      length(regexp_replace(i_product_name, '[aeiouAEIOU]', '')) AS prod_name_consonants_len,
      cardinality(split(regexp_replace(i_product_name, '[^a-zA-Z]', ' '), ' ')) AS prod_word_count,
      concat_ws(' | ',
                coalesce(cc_name, ''),
                coalesce(cc_manager, ''),
                coalesce(p_promo_name, ''),
                i_brand,
                i_manufact,
                i_color,
                i_size,
                c_email_address) AS composite_str,
      length(concat_ws(' | ',
                coalesce(cc_name, ''),
                coalesce(cc_manager, ''),
                coalesce(p_promo_name, ''),
                i_brand,
                i_manufact,
                i_color,
                i_size,
                c_email_address)) AS composite_len,
      lower(concat_ws(' | ',
                coalesce(cc_name, ''),
                coalesce(cc_manager, ''),
                coalesce(p_promo_name, ''),
                i_brand,
                i_manufact,
                i_color,
                i_size,
                c_email_address)) AS composite_lc,
      regexp_replace(concat_ws(' | ',
                coalesce(cc_name, ''),
                coalesce(cc_manager, ''),
                coalesce(p_promo_name, ''),
                i_brand,
                i_manufact,
                i_color,
                i_size,
                c_email_address), '[^a-z0-9|]', '') AS composite_alnum,
      replace(concat_ws(' | ',
                coalesce(cc_name, ''),
                coalesce(cc_manager, ''),
                coalesce(p_promo_name, ''),
                i_brand,
                i_manufact,
                i_color,
                i_size,
                c_email_address), ' ', '_') AS composite_uscore,
      cardinality(split(concat_ws(' | ',
                coalesce(cc_name, ''),
                coalesce(cc_manager, ''),
                coalesce(p_promo_name, ''),
                i_brand,
                i_manufact,
                i_color,
                i_size,
                c_email_address), '\\|')) AS composite_part_count,
      lower(concat_ws('_', c_first_name, c_last_name, c_email_address)) AS cust_fingerprint,
      length(lower(concat_ws('_', c_first_name, c_last_name, c_email_address))) AS cust_fingerprint_len,
      regexp_like(c_email_address, '@example\\.com$') AS is_example_com,
      concat_ws(', ', ca_street_number, ca_street_name, ca_city, ca_state, ca_zip) AS full_address,
      length(concat_ws(', ', ca_street_number, ca_street_name, ca_city, ca_state, ca_zip)) AS full_address_len,
      replace(concat_ws(', ', ca_street_number, ca_street_name, ca_city, ca_state, ca_zip), ' ', '') AS address_nospace,
      length(replace(concat_ws(', ', ca_street_number, ca_street_name, ca_city, ca_state, ca_zip), ' ', '')) AS address_nospace_len,
      date_format(d_date, '%Y%m%d') AS ymd_key,
      sum(cs_net_paid) OVER (PARTITION BY cs_order_number) AS order_total_net_paid,
      avg(cs_quantity) OVER (PARTITION BY cs_order_number) AS order_avg_qty
   FROM sales_facts
   WHERE regexp_like(i_product_name, '^[A-Z].*')
) s
ORDER BY s.order_total_net_paid DESC
LIMIT 100
