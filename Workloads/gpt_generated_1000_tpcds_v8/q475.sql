WITH filtered_sales AS (
   SELECT
     i.i_item_id,
     i.i_brand,
     p.p_promo_id,
     cd.cd_gender,
     hd.hd_buy_potential,
     cs.cs_ext_sales_price AS ext_sales,
     cs.cs_net_profit AS net_profit,
     cs.cs_quantity AS quantity,
     CONCAT(i.i_brand, '-', hd.hd_buy_potential) AS brand_buy_combo
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE regexp_like(p.p_channel_details, '.*[A-Z][a-z]+.*')
     AND p.p_channel_email = 'N'
     AND i.i_item_desc LIKE '%steel%'
),

sales_agg AS (
   SELECT
     i_brand,
     hd_buy_potential,
     cd_gender,
     p_promo_id,
     SUM(ext_sales) AS total_sales,
     SUM(net_profit) AS total_profit,
     SUM(quantity) AS total_qty,
     COUNT(*) AS sales_cnt,
     brand_buy_combo
   FROM filtered_sales
   GROUP BY CUBE (i_brand, hd_buy_potential, cd_gender, p_promo_id, brand_buy_combo)
),

item_sample AS (
   SELECT i_item_id, i_item_desc, i_brand
   FROM item TABLESAMPLE BERNOULLI (10)
),

agg_with_promo AS (
   SELECT
     s.i_brand,
     s.hd_buy_potential,
     s.cd_gender,
     s.p_promo_id,
     s.total_sales,
     s.total_profit,
     s.total_qty,
     s.sales_cnt,
     s.brand_buy_combo,
     regexp_extract(p.p_promo_name, '(\\w+)', 1) AS promo_word,
     substring(p.p_promo_name FROM 1 FOR 5) AS promo_prefix,
     l.promo_brand_concat
   FROM sales_agg s
   JOIN item_sample i ON s.i_brand = i.i_brand
   JOIN promotion p ON s.p_promo_id = p.p_promo_id
   CROSS JOIN LATERAL (
       SELECT concat(p.p_promo_id, '-', s.i_brand) AS promo_brand_concat
   ) l
)
SELECT
  i_brand,
  hd_buy_potential,
  cd_gender,
  p_promo_id,
  total_sales,
  total_profit,
  total_qty,
  sales_cnt,
  brand_buy_combo,
  promo_word,
  promo_prefix,
  promo_brand_concat
FROM agg_with_promo
UNION DISTINCT
SELECT
  NULL AS i_brand,
  NULL AS hd_buy_potential,
  NULL AS cd_gender,
  wp.wp_type AS p_promo_id,
  0.0 AS total_sales,
  0.0 AS total_profit,
  0 AS total_qty,
  COUNT(*) AS sales_cnt,
  NULL AS brand_buy_combo,
  wp.wp_url AS promo_word,
  substring(wp.wp_url FROM 1 FOR 5) AS promo_prefix,
  NULL AS promo_brand_concat
FROM web_page wp
JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
WHERE wp.wp_url LIKE '%catalog%'
  AND regexp_like(wp.wp_type, '^A.*')
GROUP BY CUBE (wp.wp_type, wp.wp_url)
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
