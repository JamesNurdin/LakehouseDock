WITH sales_data AS (
   SELECT
     cs.cs_order_number,
     cs.cs_sold_date_sk,
     cs.cs_item_sk,
     cs.cs_bill_customer_sk,
     cs.cs_promo_sk,
     cs.cs_call_center_sk,
     cs.cs_bill_addr_sk,
     cs.cs_net_paid,
     cp.cp_description,
     i.i_item_desc,
     i.i_product_name,
     i.i_color,
     i.i_size,
     i.i_units,
     i.i_container,
     p.p_promo_name,
     p.p_channel_details,
     c.c_customer_id,
     c.c_first_name,
     c.c_last_name,
     c.c_email_address,
     ca.ca_city,
     ca.ca_street_number,
     ca.ca_street_name,
     ca.ca_street_type,
     ca.ca_suite_number,
     ca.ca_zip,
     ca.ca_state,
     cc.cc_manager,
     cc.cc_hours,
     d.d_month_seq,
     d.d_day_name
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
   JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2001 AND 2002
)
SELECT
   concat_ws('#',
     s.c_customer_id,
     lower(regexp_replace(concat(s.c_first_name, ' ', s.c_last_name), '\\s+', '_')),
     regexp_replace(s.c_email_address, '[^a-zA-Z0-9@]', ''),
     substr(split(s.c_email_address, '@')[1], 1, 8),
     replace(s.ca_city, ' ', ''),
     upper(s.i_color),
     lower(regexp_replace(s.i_product_name, '\\s+', '-')),
     lpad(cast(s.d_month_seq as varchar), 3, '0'),
     case when lower(s.p_promo_name) like '%discount%' then 'DISC' else 'NOD' end,
     regexp_replace(s.p_channel_details, '\\W', ''),
     reverse(s.cc_manager),
     concat(substr(s.cc_hours, 1, 2), ':', substr(s.cc_hours, 3, 2))
   ) as complex_key,
   count(*) as cnt,
   sum(s.cs_net_paid) as total_net,
   avg(length(s.i_item_desc)) as avg_item_desc_len,
   sum(length(s.cp_description)) as total_desc_len,
   max(s.d_day_name) as any_day_name,
   min(length(s.c_email_address) - length(replace(s.c_email_address, '@', ''))) as min_at_symbols
FROM sales_data s
GROUP BY
   concat_ws('#',
     s.c_customer_id,
     lower(regexp_replace(concat(s.c_first_name, ' ', s.c_last_name), '\\s+', '_')),
     regexp_replace(s.c_email_address, '[^a-zA-Z0-9@]', ''),
     substr(split(s.c_email_address, '@')[1], 1, 8),
     replace(s.ca_city, ' ', ''),
     upper(s.i_color),
     lower(regexp_replace(s.i_product_name, '\\s+', '-')),
     lpad(cast(s.d_month_seq as varchar), 3, '0'),
     case when lower(s.p_promo_name) like '%discount%' then 'DISC' else 'NOD' end,
     regexp_replace(s.p_channel_details, '\\W', ''),
     reverse(s.cc_manager),
     concat(substr(s.cc_hours, 1, 2), ':', substr(s.cc_hours, 3, 2))
   )
HAVING sum(s.cs_net_paid) > 1000
ORDER BY total_net DESC
LIMIT 50
