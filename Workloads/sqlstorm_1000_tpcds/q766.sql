WITH enriched AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    cc.cc_name,
    cc.cc_manager,
    cc.cc_hours,
    i.i_item_id,
    i.i_product_name,
    i.i_item_desc,
    cs.cs_quantity,
    cs.cs_net_paid,
    length(i.i_item_desc) AS desc_len,
    length(regexp_replace(i.i_item_desc, '[^A-Za-z]', '')) AS alpha_len,
    cardinality(split(i.i_item_desc, '\\s+')) AS word_cnt,
    CASE WHEN regexp_like(i.i_item_desc, '\\d') THEN 1 ELSE 0 END AS has_digit,
    regexp_extract(i.i_item_desc, '(\\d+)', 1) AS first_number,
    reverse(cc.cc_manager) AS rev_manager,
    substring(cc.cc_hours, 1, 5) AS open_time,
    c.c_customer_sk,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    lower(c.c_email_address) AS email_lower,
    split_part(lower(c.c_email_address), '@', 2) AS email_domain,
    p.p_promo_name,
    lower(p.p_promo_name) AS promo_name_lower,
    length(lower(p.p_promo_name)) AS promo_name_len,
    regexp_replace(p.p_promo_name, '[^A-Za-z]', '') AS promo_clean,
    regexp_extract(lower(p.p_promo_name), '(sale|discount|promo)', 1) AS promo_keyword,
    cp.cp_description,
    cardinality(split(cp.cp_description, '\\s+')) AS cp_word_cnt,
    replace(cp.cp_description, '\n', ' ') AS cp_desc_clean
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
)
SELECT
  d_year,
  d_month_seq,
  cc_name,
  count(*) AS total_transactions,
  sum(cs_net_paid) AS total_net_paid,
  avg(desc_len) AS avg_desc_len,
  avg(alpha_len) AS avg_alpha_len,
  avg(word_cnt) AS avg_word_cnt,
  sum(CASE WHEN has_digit = 1 THEN cs_quantity ELSE 0 END) AS qty_items_with_digits,
  approx_percentile(alpha_len, 0.5) AS median_alpha_len,
  count(DISTINCT i_item_id) AS distinct_items,
  count(DISTINCT c_customer_sk) AS distinct_customers,
  max_by(rev_manager, desc_len) AS rev_manager_of_longest_desc,
  max_by(promo_name_lower, promo_name_len) AS longest_promo_name,
  array_join(array_agg(DISTINCT email_domain), ',') AS distinct_email_domains,
  array_join(array_agg(DISTINCT promo_keyword) FILTER (WHERE promo_keyword IS NOT NULL), ',') AS promo_keywords,
  max(cp_word_cnt) AS max_catalog_page_word_cnt,
  min(open_time) AS earliest_open_time,
  max(open_time) AS latest_open_time
FROM enriched
GROUP BY
  d_year,
  d_month_seq,
  cc_name
HAVING
  sum(cs_net_paid) > 100000
ORDER BY
  total_net_paid DESC
LIMIT 100
