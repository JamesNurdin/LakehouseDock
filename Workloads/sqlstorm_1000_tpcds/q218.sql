WITH processed AS (
   SELECT
      i.i_item_sk,
      concat_ws('#', i.i_brand, i.i_class, i.i_category) AS category_path,
      lower(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS clean_desc,
      replace(lower(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')), ' ', '_') AS underscored_desc,
      substring(i.i_item_desc, 1, 50) AS short_desc,
      length(i.i_item_desc) AS orig_len,
      length(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')) AS clean_len,
      length(replace(lower(regexp_replace(i.i_item_desc, '[^a-zA-Z0-9 ]', '')), ' ', '_')) AS underscored_len,
      cardinality(split(i.i_item_desc, ' ')) AS word_count,
      c.c_customer_sk,
      lower(c.c_email_address) AS email_lower,
      element_at(split(c.c_email_address, '@'), 2) AS email_domain,
      ca.ca_city,
      ca.ca_state,
      ca.ca_zip,
      concat_ws('_', ca.ca_city, ca.ca_state, ca.ca_zip) AS location_key,
      cs.cs_quantity,
      cs.cs_sales_price,
      cs.cs_ext_sales_price,
      cs.cs_net_paid,
      ws.ws_quantity AS ws_quantity,
      ws.ws_sales_price AS ws_sales_price,
      ws.ws_net_paid,
      d.d_year,
      d.d_month_seq,
      r.r_reason_desc,
      p.p_promo_name,
      p.p_channel_details,
      cc.cc_name,
      cc.cc_manager,
      concat_ws('|', i.i_product_name, i.i_color, i.i_size) AS product_variant,
      regexp_replace(concat_ws(' ', i.i_product_name, i.i_color, i.i_size), '[^a-zA-Z0-9]', '') AS alphanum_variant,
      length(regexp_replace(concat_ws(' ', i.i_product_name, i.i_color, i.i_size), '[^a-zA-Z0-9]', '')) AS variant_len,
      lower(cc.cc_name) AS cc_name_lower,
      replace(cc.cc_name, ' ', '-') AS cc_name_hyphen,
      length(cc.cc_name) AS cc_name_len
   FROM item i
   JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
   JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   WHERE i.i_item_desc IS NOT NULL
)
SELECT
   category_path,
   clean_desc,
   underscored_desc,
   short_desc,
   orig_len,
   clean_len,
   underscored_len,
   word_count,
   email_lower,
   email_domain,
   location_key,
   product_variant,
   alphanum_variant,
   variant_len,
   cc_name_lower,
   cc_name_hyphen,
   cc_name_len,
   d_year,
   d_month_seq,
   sum(cs_sales_price) AS total_sales_price,
   sum(ws_sales_price) AS total_ws_sales_price,
   count(*) AS txn_count,
   approx_distinct(c_customer_sk) AS distinct_customers,
   approx_percentile(cs_quantity, 0.5) AS median_quantity,
   approx_percentile(ws_quantity, 0.5) AS median_ws_quantity,
   max(email_domain) AS any_email_domain
FROM processed
GROUP BY
   category_path,
   clean_desc,
   underscored_desc,
   short_desc,
   orig_len,
   clean_len,
   underscored_len,
   word_count,
   email_lower,
   email_domain,
   location_key,
   product_variant,
   alphanum_variant,
   variant_len,
   cc_name_lower,
   cc_name_hyphen,
   cc_name_len,
   d_year,
   d_month_seq
HAVING sum(cs_sales_price) > 1000
ORDER BY total_sales_price DESC
LIMIT 100
