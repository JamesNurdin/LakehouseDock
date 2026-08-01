WITH store_part AS (
  SELECT
    time_dim.t_time AS sale_time,
    'store' AS channel,
    store.s_store_name AS store_name,
    item.i_category AS category,
    promotion.p_promo_name AS promo_name,
    store_sales.ss_net_paid AS net_paid,
    CASE WHEN store_sales.ss_net_paid > 1000 THEN 'high' ELSE 'low' END AS revenue_band,
    (SELECT avg(cs_ext_discount_amt) FROM catalog_sales WHERE cs_item_sk = item.i_item_sk) AS avg_catalog_discount
  FROM store_sales
  JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
  JOIN item ON store_sales.ss_item_sk = item.i_item_sk
  JOIN store ON store_sales.ss_store_sk = store.s_store_sk
  JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
  WHERE store_sales.ss_quantity > 5
    AND time_dim.t_hour BETWEEN 9 AND 18
    AND item.i_category = 'Sports'
),
web_part AS (
  SELECT
    time_dim.t_time AS sale_time,
    'web' AS channel,
    web_page.wp_url AS store_name,
    item.i_category AS category,
    promotion.p_promo_name AS promo_name,
    web_sales.ws_net_paid AS net_paid,
    CASE WHEN web_sales.ws_net_paid > 1000 THEN 'high' ELSE 'low' END AS revenue_band,
    (SELECT avg(cs_ext_discount_amt) FROM catalog_sales WHERE cs_item_sk = item.i_item_sk) AS avg_catalog_discount
  FROM web_sales
  JOIN time_dim ON web_sales.ws_sold_time_sk = time_dim.t_time_sk
  JOIN item ON web_sales.ws_item_sk = item.i_item_sk
  JOIN web_page ON web_sales.ws_web_page_sk = web_page.wp_web_page_sk
  JOIN promotion ON web_sales.ws_promo_sk = promotion.p_promo_sk
  WHERE web_sales.ws_quantity > 5
    AND time_dim.t_hour BETWEEN 9 AND 18
    AND item.i_category = 'Sports'
)
SELECT
  sale_time,
  channel,
  store_name,
  category,
  promo_name,
  net_paid,
  revenue_band,
  avg_catalog_discount
FROM store_part
UNION ALL
SELECT
  sale_time,
  channel,
  store_name,
  category,
  promo_name,
  net_paid,
  revenue_band,
  avg_catalog_discount
FROM web_part
ORDER BY net_paid DESC
LIMIT 100
