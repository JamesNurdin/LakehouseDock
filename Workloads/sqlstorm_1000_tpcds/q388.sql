WITH sales_agg AS (
 SELECT 
   lower(regexp_extract(c.c_email_address, '@(.+)$', 1)) AS email_domain,
   upper(substr(i.i_item_id, 1, 5)) || '-' || lower(regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '')) AS product_key,
   concat_ws('_', i.i_color, replace(i.i_size, ' ', ''), substr(i.i_formulation, 1, 3)) AS product_code,
   count(distinct cs.cs_order_number) AS order_count,
   sum(cs.cs_net_paid) AS total_net_paid,
   sum(cs.cs_ext_sales_price) AS total_ext_sales_price,
   avg(cs.cs_quantity) AS avg_quantity,
   min(cs.cs_ext_discount_amt) AS min_discount,
   max(cs.cs_ext_discount_amt) AS max_discount,
   sum(CASE WHEN lower(trim(cp.cp_type)) = 'promotion' THEN cs.cs_net_paid ELSE 0 END) AS promo_sales,
   length(i.i_product_name) AS product_name_len,
   regexp_replace(i.i_item_desc, '\\s+', ' ') AS cleaned_item_desc
 FROM catalog_sales cs
 JOIN item i ON cs.cs_item_sk = i.i_item_sk
 JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
 LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
 WHERE cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2001)
   AND c.c_email_address IS NOT NULL
   AND regexp_like(c.c_email_address, '^[^@]+@[^@]+[.][^@]+$')
 GROUP BY 
   lower(regexp_extract(c.c_email_address, '@(.+)$', 1)),
   upper(substr(i.i_item_id, 1, 5)) || '-' || lower(regexp_replace(i.i_product_name, '[^A-Za-z0-9]', '')),
   concat_ws('_', i.i_color, replace(i.i_size, ' ', ''), substr(i.i_formulation, 1, 3)),
   length(i.i_product_name),
   regexp_replace(i.i_item_desc, '\\s+', ' ')
 HAVING sum(cs.cs_net_paid) > 1000
)
SELECT
   email_domain,
   product_key,
   product_code,
   order_count,
   total_net_paid,
   total_ext_sales_price,
   avg_quantity,
   min_discount,
   max_discount,
   promo_sales,
   product_name_len,
   cleaned_item_desc,
   row_number() OVER (PARTITION BY email_domain ORDER BY total_net_paid DESC) AS domain_product_rank
FROM sales_agg
ORDER BY total_net_paid DESC
LIMIT 100
