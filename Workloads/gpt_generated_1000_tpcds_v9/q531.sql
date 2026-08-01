SELECT
  p.p_promo_name,
  regexp_extract(p.p_promo_name, '[0-9]+') AS promo_code,
  sm.sm_ship_mode_id,
  d.d_year,
  d.d_month_seq,
  substring(p.p_promo_name, 1, 10) AS promo_name_prefix,
  any_value(regexp_extract(i.i_item_desc, '([A-Za-z]+)')) AS item_desc_first_word,
  any_value(regexp_extract(c.c_email_address, '@(.*)$')) AS email_domain,
  sum(cs.cs_net_paid) AS total_net_paid,
  sum(cs.cs_net_profit) AS total_net_profit,
  count(distinct cs.cs_bill_customer_sk) AS unique_customers,
  concat(p.p_promo_name, ' - ', sm.sm_ship_mode_id) AS promo_ship_mode_label
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
WHERE d.d_date >= DATE '2000-01-01'
  AND d.d_date < DATE '2000-04-01'
  AND regexp_like(p.p_promo_name, '^Promo[0-9]+$')
  AND c.c_email_address LIKE '%@example.com'
  AND regexp_like(i.i_item_desc, '(Gold|Silver)')
GROUP BY
  p.p_promo_name,
  sm.sm_ship_mode_id,
  d.d_year,
  d.d_month_seq
ORDER BY total_net_paid DESC
LIMIT 100
