WITH unified_sales AS (
  SELECT 'store' AS channel,
         ss_sold_date_sk AS sold_date_sk,
         ss_item_sk AS item_sk,
         ss_store_sk AS location_sk,
         ss_promo_sk AS promo_sk,
         ss_quantity AS quantity,
         ss_net_paid AS net_paid,
         ss_ext_discount_amt AS discount_amt,
         ss_net_profit AS net_profit
  FROM store_sales
  UNION ALL
  SELECT 'catalog' AS channel,
         cs_sold_date_sk AS sold_date_sk,
         cs_item_sk AS item_sk,
         cs_call_center_sk AS location_sk,
         cs_promo_sk AS promo_sk,
         cs_quantity AS quantity,
         cs_net_paid AS net_paid,
         cs_ext_discount_amt AS discount_amt,
         cs_net_profit AS net_profit
  FROM catalog_sales
  UNION ALL
  SELECT 'web' AS channel,
         ws_sold_date_sk AS sold_date_sk,
         ws_item_sk AS item_sk,
         ws_web_site_sk AS location_sk,
         ws_promo_sk AS promo_sk,
         ws_quantity AS quantity,
         ws_net_paid AS net_paid,
         ws_ext_discount_amt AS discount_amt,
         ws_net_profit AS net_profit
  FROM web_sales
),
joined_sales AS (
  SELECT us.channel,
         d.d_year,
         i.i_category,
         i.i_brand,
         COALESCE(s.s_store_name, cc.cc_name, ws.web_name) AS location_name,
         us.quantity,
         us.net_paid,
         us.discount_amt,
         us.net_profit,
         p.p_cost AS promo_cost,
         p.p_discount_active AS promo_active
  FROM unified_sales us
  LEFT JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON us.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON us.promo_sk = p.p_promo_sk
  LEFT JOIN store s ON us.channel = 'store' AND us.location_sk = s.s_store_sk
  LEFT JOIN call_center cc ON us.channel = 'catalog' AND us.location_sk = cc.cc_call_center_sk
  LEFT JOIN web_site ws ON us.channel = 'web' AND us.location_sk = ws.web_site_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
),
aggregated AS (
  SELECT channel,
         d_year,
         i_category,
         i_brand,
         SUM(quantity) AS total_quantity,
         SUM(net_paid) AS total_net_paid,
         SUM(net_profit) AS total_net_profit,
         SUM(discount_amt) AS total_discount,
         AVG(CASE WHEN net_paid <> 0 THEN discount_amt / net_paid END) AS avg_discount_pct,
         SUM(CASE WHEN promo_active = 'Y' THEN promo_cost ELSE 0 END) AS total_active_promo_cost
  FROM joined_sales
  GROUP BY channel, d_year, i_category, i_brand
),
location_sales AS (
  SELECT channel,
         d_year,
         i_category,
         i_brand,
         location_name,
         SUM(net_paid) AS location_net_paid
  FROM joined_sales
  GROUP BY channel, d_year, i_category, i_brand, location_name
),
ranked_locations AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY channel, d_year, i_category, i_brand ORDER BY location_net_paid DESC) AS rn
  FROM location_sales
)
SELECT a.channel,
       a.d_year,
       a.i_category,
       a.i_brand,
       a.total_quantity,
       a.total_net_paid,
       a.total_net_profit,
       a.total_discount,
       a.avg_discount_pct,
       a.total_active_promo_cost,
       ARRAY_AGG(r.location_name ORDER BY r.location_net_paid DESC) FILTER (WHERE r.rn <= 3) AS top_3_locations
FROM aggregated a
LEFT JOIN ranked_locations r
  ON a.channel = r.channel
 AND a.d_year = r.d_year
 AND a.i_category = r.i_category
 AND a.i_brand = r.i_brand
GROUP BY a.channel, a.d_year, a.i_category, a.i_brand,
         a.total_quantity, a.total_net_paid, a.total_net_profit,
         a.total_discount, a.avg_discount_pct, a.total_active_promo_cost
