WITH
cust AS (
   SELECT
      c_customer_sk,
      c_first_name,
      c_last_name,
      concat_ws(' ', trim(c_first_name), trim(c_last_name)) AS full_name,
      upper(concat_ws(' ', trim(c_first_name), trim(c_last_name))) AS full_name_up,
      length(concat_ws(' ', trim(c_first_name), trim(c_last_name))) AS full_name_len,
      lower(c_email_address) AS email_lc,
      regexp_extract(c_email_address, '@([^.]*)', 1) AS email_domain,
      replace(c_email_address, '.', '_') AS email_underscore,
      CASE WHEN c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_status,
      substring(c_first_name, 1, 1) AS first_initial,
      substring(c_last_name, 1, 1) AS last_initial
   FROM customer
),
itm AS (
   SELECT
      i_item_sk,
      i_product_name,
      upper(i_product_name) AS product_name_up,
      lower(i_product_name) AS product_name_lc,
      length(i_product_name) AS product_name_len,
      regexp_replace(i_product_name, '\\s+', ' ') AS product_name_norm,
      cardinality(split(i_product_name, '\\s+')) AS product_name_word_count,
      i_color,
      i_size,
      i_brand
   FROM item
),
call_ctr AS (
   SELECT
      cc_call_center_sk,
      cc_name,
      lower(cc_name) AS cc_name_lc,
      regexp_replace(cc_name, '[^A-Za-z0-9]', '') AS cc_name_alnum,
      substring(cc_hours, 1, 5) AS cc_hours_prefix
   FROM call_center
),
joined AS (
   SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_call_center_sk,
      cs.cs_bill_customer_sk,
      cs.cs_item_sk,
      c.full_name,
      c.full_name_up,
      c.full_name_len,
      c.email_domain,
      c.cust_status,
      c.first_initial,
      c.last_initial,
      i.product_name_up,
      i.product_name_norm,
      i.product_name_word_count,
      cc.cc_name,
      cc.cc_name_alnum,
      d.d_year,
      d.d_month_seq,
      d.d_day_name
   FROM catalog_sales cs
   JOIN cust c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN itm i ON cs.cs_item_sk = i.i_item_sk
   JOIN call_ctr cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE c.email_domain IS NOT NULL
     AND i.product_name_word_count > 1
),
agg AS (
   SELECT
      d_year,
      d_month_seq,
      email_domain,
      substring(full_name, 1, 1) AS name_first_letter,
      cust_status,
      count(*) AS txn_cnt,
      sum(cs_net_paid) AS total_paid,
      sum(cs_net_profit) AS total_profit,
      avg(full_name_len) AS avg_name_len,
      max(full_name_len) AS max_name_len,
      cardinality(array_agg(DISTINCT cc_name_alnum)) AS unique_call_center_count,
      concat_ws('|', array_agg(DISTINCT email_domain)) AS email_domains_concat
   FROM joined
   GROUP BY d_year, d_month_seq, email_domain, substring(full_name, 1, 1), cust_status
)
SELECT
   d_year,
   d_month_seq,
   email_domain,
   name_first_letter,
   cust_status,
   txn_cnt,
   total_paid,
   total_profit,
   avg_name_len,
   max_name_len,
   unique_call_center_count,
   email_domains_concat
FROM agg
ORDER BY total_paid DESC
LIMIT 100
