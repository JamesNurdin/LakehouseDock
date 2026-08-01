WITH base AS (
  SELECT
    i.i_item_id,
    wsite.web_site_id,
    wp.wp_type,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_net_profit,
    ws.ws_sales_price,
    p.p_promo_id,
    inv.inv_quantity_on_hand,
    p.p_discount_active,
    p.p_channel_event,
    wp.wp_max_ad_count,
    wp.wp_rec_start_date
  FROM web_sales ws
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
   AND p.p_item_sk = i.i_item_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE inv.inv_quantity_on_hand > 500
    AND p.p_discount_active = 'Y'
    AND p.p_channel_event = 'N'
    AND wp.wp_rec_start_date BETWEEN DATE '1999-01-01' AND DATE '2000-12-31'
    AND wp.wp_max_ad_count >= 2
    AND ws.ws_sales_price > 100
    AND NOT EXISTS (
      SELECT 1
      FROM promotion p2
      WHERE p2.p_item_sk = i.i_item_sk
        AND p2.p_channel_event = 'Y'
    )
),
aggregated_union AS (
  SELECT
    i_item_id,
    web_site_id,
    CAST(NULL AS varchar) AS page_type,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_ext_discount_amt) AS avg_discount,
    SUM(ws_net_profit) AS total_net_profit,
    MIN(ws_sales_price) AS min_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    COUNT(DISTINCT p_promo_id) AS distinct_promo_count
  FROM base
  GROUP BY i_item_id, web_site_id
  UNION ALL
  SELECT
    i_item_id,
    CAST(NULL AS varchar) AS web_site_id,
    wp_type AS page_type,
    SUM(ws_quantity) AS total_quantity,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_ext_discount_amt) AS avg_discount,
    SUM(ws_net_profit) AS total_net_profit,
    MIN(ws_sales_price) AS min_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    COUNT(DISTINCT p_promo_id) AS distinct_promo_count
  FROM base
  GROUP BY i_item_id, wp_type
)
SELECT
  i_item_id,
  web_site_id,
  page_type,
  total_quantity,
  total_sales,
  avg_discount,
  total_net_profit,
  min_sales_price,
  max_sales_price,
  distinct_promo_count,
  RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
  SUM(total_sales) OVER (PARTITION BY i_item_id) AS sales_by_item_total
FROM aggregated_union
ORDER BY total_sales DESC
LIMIT 100
