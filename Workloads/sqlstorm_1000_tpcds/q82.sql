WITH sales_all AS (
  SELECT cs.cs_sold_date_sk AS date_sk,
         cs.cs_item_sk AS item_sk,
         cs.cs_call_center_sk AS channel_sk,
         'catalog' AS channel,
         cs.cs_quantity AS quantity,
         cs.cs_ext_sales_price AS ext_sales_price,
         cs.cs_net_profit AS profit,
         cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT ss.ss_sold_date_sk AS date_sk,
         ss.ss_item_sk AS item_sk,
         ss.ss_store_sk AS channel_sk,
         'store' AS channel,
         ss.ss_quantity AS quantity,
         ss.ss_ext_sales_price AS ext_sales_price,
         ss.ss_net_profit AS profit,
         ss.ss_promo_sk AS promo_sk
  FROM store_sales ss
  UNION ALL
  SELECT ws.ws_sold_date_sk AS date_sk,
         ws.ws_item_sk AS item_sk,
         ws.ws_web_page_sk AS channel_sk,
         'web' AS channel,
         ws.ws_quantity AS quantity,
         ws.ws_ext_sales_price AS ext_sales_price,
         ws.ws_net_profit AS profit,
         ws.ws_promo_sk AS promo_sk
  FROM web_sales ws
),
date_dim_filtered AS (
  SELECT d.d_date_sk,
         d.d_year,
         d.d_month_seq
  FROM date_dim d
  WHERE d.d_year BETWEEN 1999 AND 2001
),
item_dim AS (
  SELECT i.i_item_sk,
         i.i_category,
         i.i_brand
  FROM item i
),
promo_dim AS (
  SELECT p.p_promo_sk,
         p.p_discount_active
  FROM promotion p
),
sales_agg AS (
  SELECT
    da.d_year,
    da.d_month_seq,
    s.channel,
    i.i_category,
    i.i_brand,
    MAX(COALESCE(cc.cc_name, st.s_store_name, wp.wp_url)) AS channel_name,
    SUM(s.quantity) AS total_quantity,
    SUM(s.ext_sales_price) AS total_sales,
    SUM(s.profit) AS total_profit,
    SUM(CASE WHEN s.promo_sk IS NOT NULL THEN s.ext_sales_price * 0.1 ELSE 0 END) AS promo_estimated_discount,
    COUNT(DISTINCT s.item_sk) AS distinct_items_sold,
    approx_percentile(s.ext_sales_price, 0.5) AS median_sale_price
  FROM sales_all s
  JOIN date_dim_filtered da ON s.date_sk = da.d_date_sk
  JOIN item_dim i ON s.item_sk = i.i_item_sk
  LEFT JOIN promo_dim p ON s.promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON s.channel = 'catalog' AND s.channel_sk = cc.cc_call_center_sk
  LEFT JOIN store st ON s.channel = 'store' AND s.channel_sk = st.s_store_sk
  LEFT JOIN web_page wp ON s.channel = 'web' AND s.channel_sk = wp.wp_web_page_sk
  WHERE s.channel IN ('catalog', 'store', 'web')
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
  GROUP BY ROLLUP (da.d_year, da.d_month_seq, s.channel, i.i_category, i.i_brand)
  HAVING SUM(s.ext_sales_price) > 0
)
SELECT
  a.d_year,
  a.d_month_seq,
  a.channel,
  a.channel_name,
  a.i_category,
  a.i_brand,
  a.total_quantity,
  a.total_sales,
  a.total_profit,
  a.promo_estimated_discount,
  a.distinct_items_sold,
  a.median_sale_price,
  ROW_NUMBER() OVER (PARTITION BY a.d_year, a.channel ORDER BY a.total_profit DESC) AS profit_rank_by_channel_year
FROM sales_agg a
ORDER BY a.d_year, a.d_month_seq, profit_rank_by_channel_year
LIMIT 100
