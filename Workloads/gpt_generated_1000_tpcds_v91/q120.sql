SELECT
    s.s_store_id,
    s.s_store_sk,
    s.s_store_name,
    p.p_promo_id,
    p.p_channel_details,
    regexp_extract(p.p_promo_name, '(\\d+)', 1) AS promo_number,
    CONCAT(p.p_promo_id, '-', substring(p.p_promo_name, 1, 5)) AS promo_label,
    sum(ss.ss_net_profit) AS total_net_profit,
    sum(ss.ss_ext_sales_price) AS total_sales,
    (SELECT sum(sr.sr_return_amt) FROM store_returns sr WHERE sr.sr_store_sk = s.s_store_sk) AS total_return_amount,
    count(distinct ss.ss_item_sk) AS distinct_items_sold
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_year = 2020
  AND p.p_discount_active = 'Y'
  AND regexp_like(p.p_channel_details, 'common')
  AND regexp_like(p.p_promo_id, '^P[0-9]{3}$')
  AND p.p_promo_name LIKE '%sale%'
  AND EXISTS (
      SELECT 1
      FROM catalog_sales cs
      JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
      WHERE cs.cs_promo_sk = p.p_promo_sk
        AND regexp_like(cp.cp_description, 'discount')
  )
GROUP BY
    s.s_store_id,
    s.s_store_sk,
    s.s_store_name,
    p.p_promo_id,
    p.p_channel_details,
    regexp_extract(p.p_promo_name, '(\\d+)', 1),
    CONCAT(p.p_promo_id, '-', substring(p.p_promo_name, 1, 5))
HAVING sum(ss.ss_net_profit) > 1000000
ORDER BY total_net_profit DESC
LIMIT 100
