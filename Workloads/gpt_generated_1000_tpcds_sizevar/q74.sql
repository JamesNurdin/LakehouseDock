WITH sales_enriched AS (
  SELECT
    s.s_city,
    s.s_store_name,
    c.c_preferred_cust_flag,
    i.i_item_desc,
    i.i_item_id,
    p.p_promo_name,
    d.d_year,
    ss.ss_quantity,
    ss.ss_net_paid
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE i.i_item_desc LIKE '%steel%'
    AND regexp_like(s.s_store_name, '^Store [A-Z]+')
    AND substr(c.c_preferred_cust_flag, 1, 1) = 'Y'
)
SELECT
  CASE WHEN grouping(s_city) = 0 THEN s_city ELSE 'All Cities' END AS city,
  CASE WHEN grouping(c_preferred_cust_flag) = 0 THEN c_preferred_cust_flag ELSE 'All Flags' END AS preferred_flag,
  concat(substr(any_value(i_item_desc), 1, 15), '...') AS short_desc,
  regexp_extract(any_value(i_item_id), '[0-9]+') AS item_number,
  sum(ss_quantity) AS total_qty,
  sum(ss_net_paid) AS total_sales,
  count(*) AS txn_count
FROM sales_enriched
GROUP BY GROUPING SETS (
  (s_city, c_preferred_cust_flag),
  (s_city),
  (c_preferred_cust_flag)
)
ORDER BY total_sales DESC
LIMIT 100
