WITH transformed_sales AS (
   SELECT
       ss.ss_sold_date_sk,
       ss.ss_item_sk,
       ss.ss_customer_sk,
       ss.ss_net_paid,
       ss.ss_net_profit,
       i.i_product_name,
       lower(i.i_product_name) AS product_name_lc,
       regexp_replace(i.i_product_name, '(?i)[^a-z0-9]', '') AS product_name_alnum,
       length(i.i_product_name) AS product_name_len,
       substr(i.i_product_name, 1, 10) AS product_name_prefix,
       reverse(i.i_product_name) AS product_name_rev,
       regexp_extract(i.i_product_name, '(\\d+)', 1) AS product_name_first_number,
       split(i.i_product_name, ' ')[1] AS product_name_first_word,
       concat_ws('|', i.i_brand, i.i_class, i.i_category) AS product_hierarchy,
       concat_ws(' ', c.c_first_name, c.c_last_name) AS full_cust_name,
       upper(c.c_email_address) AS email_uc,
       regexp_replace(c.c_email_address, '([a-zA-Z0-9_.+-]+)@([a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+)', '\\1_at_\\2') AS email_obfusc,
       replace(c.c_first_name, 'a', '@') AS first_name_obf,
       c.c_first_name AS original_first_name,
       d.d_year,
       format('%s-W%s', d.d_year, d.d_week_seq) AS year_week
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
)
SELECT
    year_week,
    product_hierarchy,
    count(*) AS sales_cnt,
    sum(ss_net_paid) AS total_net_paid,
    sum(ss_net_profit) AS total_net_profit,
    avg(product_name_len) AS avg_name_len,
    approx_percentile(product_name_len, 0.5) AS median_name_len,
    min(product_name_rev) AS min_rev_name,
    max(product_name_rev) AS max_rev_name,
    count(DISTINCT email_obfusc) AS uniq_obf_emails,
    sum(CASE WHEN regexp_like(product_name_alnum, '^.*[0-9]{3,}.*$') THEN 1 ELSE 0 END) AS cnt_name_with_3plus_digits,
    sum(CASE WHEN lower(full_cust_name) LIKE '%smith%' THEN ss_net_paid ELSE 0 END) AS net_paid_smith,
    sum(CASE WHEN first_name_obf != original_first_name THEN 1 ELSE 0 END) AS cnt_first_name_obf
FROM transformed_sales
GROUP BY
    year_week,
    product_hierarchy
ORDER BY total_net_paid DESC
LIMIT 100
