WITH sales_union AS (
  SELECT 
    cs.cs_sold_date_sk AS date_sk,
    cs.cs_item_sk AS item_sk,
    cs.cs_quantity AS quantity,
    cs.cs_net_paid AS net_paid,
    cs.cs_net_profit AS net_profit,
    cs.cs_ext_sales_price AS ext_sales_price,
    cs.cs_ext_discount_amt AS ext_discount_amt,
    cs.cs_promo_sk AS promo_sk,
    'catalog' AS channel,
    cs.cs_call_center_sk AS call_center_sk,
    CAST(NULL AS integer) AS store_sk,
    CAST(NULL AS integer) AS web_page_sk,
    CAST(NULL AS integer) AS web_site_sk
  FROM catalog_sales cs
  UNION ALL
  SELECT 
    ss.ss_sold_date_sk AS date_sk,
    ss.ss_item_sk AS item_sk,
    ss.ss_quantity AS quantity,
    ss.ss_net_paid AS net_paid,
    ss.ss_net_profit AS net_profit,
    ss.ss_ext_sales_price AS ext_sales_price,
    ss.ss_ext_discount_amt AS ext_discount_amt,
    ss.ss_promo_sk AS promo_sk,
    'store' AS channel,
    CAST(NULL AS integer) AS call_center_sk,
    ss.ss_store_sk AS store_sk,
    CAST(NULL AS integer) AS web_page_sk,
    CAST(NULL AS integer) AS web_site_sk
  FROM store_sales ss
  UNION ALL
  SELECT 
    ws.ws_sold_date_sk AS date_sk,
    ws.ws_item_sk AS item_sk,
    ws.ws_quantity AS quantity,
    ws.ws_net_paid AS net_paid,
    ws.ws_net_profit AS net_profit,
    ws.ws_ext_sales_price AS ext_sales_price,
    ws.ws_ext_discount_amt AS ext_discount_amt,
    ws.ws_promo_sk AS promo_sk,
    'web' AS channel,
    CAST(NULL AS integer) AS call_center_sk,
    CAST(NULL AS integer) AS store_sk,
    ws.ws_web_page_sk AS web_page_sk,
    ws.ws_web_site_sk AS web_site_sk
  FROM web_sales ws
),
inventory_agg AS (
  SELECT inv_date_sk AS date_sk, inv_item_sk AS item_sk,
         SUM(inv_quantity_on_hand) AS total_on_hand
  FROM inventory
  GROUP BY inv_date_sk, inv_item_sk
),
sales_full AS (
  SELECT
    su.*,
    d.d_year,
    d.d_quarter_name,
    i.i_item_id,
    i.i_item_desc,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    COALESCE(cc.cc_name, s.s_store_name, wp.wp_url) AS channel_name,
    p.p_discount_active,
    ia.total_on_hand
  FROM sales_union su
  LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
  LEFT JOIN item i ON su.item_sk = i.i_item_sk
  LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
  LEFT JOIN call_center cc ON su.call_center_sk = cc.cc_call_center_sk
  LEFT JOIN store s ON su.store_sk = s.s_store_sk
  LEFT JOIN web_page wp ON su.web_page_sk = wp.wp_web_page_sk
  LEFT JOIN inventory_agg ia ON su.date_sk = ia.date_sk AND su.item_sk = ia.item_sk
)
SELECT
  channel,
  d_quarter_name AS quarter,
  SUM(net_profit) AS total_net_profit,
  SUM(net_paid) AS total_net_paid,
  SUM(quantity) AS total_quantity,
  SUM(ext_discount_amt) / NULLIF(SUM(ext_sales_price), 0) AS avg_discount_ratio,
  COUNT(DISTINCT CASE WHEN channel = 'catalog' THEN call_center_sk END) AS distinct_call_centers,
  COUNT(DISTINCT CASE WHEN channel = 'store' THEN store_sk END) AS distinct_stores,
  COUNT(DISTINCT CASE WHEN channel = 'web' THEN web_page_sk END) AS distinct_web_pages,
  SUM(total_on_hand) AS total_inventory_on_hand,
  ROW_NUMBER() OVER (PARTITION BY channel ORDER BY SUM(net_profit) DESC) AS profit_rank
FROM sales_full
WHERE d_year BETWEEN 2000 AND 2002
GROUP BY ROLLUP (channel, d_quarter_name)
HAVING channel IS NOT NULL
ORDER BY channel, d_quarter_name
