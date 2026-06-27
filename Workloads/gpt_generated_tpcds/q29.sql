WITH store_sales_promo AS (
  SELECT
    sale_date.d_year AS year,
    item.i_category AS category,
    store_sales.ss_net_profit AS net_profit,
    'store' AS channel
  FROM store_sales
  JOIN date_dim AS sale_date
    ON store_sales.ss_sold_date_sk = sale_date.d_date_sk
  JOIN item
    ON store_sales.ss_item_sk = item.i_item_sk
  JOIN promotion
    ON store_sales.ss_promo_sk = promotion.p_promo_sk
  JOIN date_dim AS promo_start
    ON promotion.p_start_date_sk = promo_start.d_date_sk
  JOIN date_dim AS promo_end
    ON promotion.p_end_date_sk = promo_end.d_date_sk
  WHERE sale_date.d_date BETWEEN promo_start.d_date AND promo_end.d_date
    AND promotion.p_discount_active = 'Y'
),
catalog_sales_promo AS (
  SELECT
    sale_date.d_year AS year,
    item.i_category AS category,
    catalog_sales.cs_net_profit AS net_profit,
    'catalog' AS channel
  FROM catalog_sales
  JOIN date_dim AS sale_date
    ON catalog_sales.cs_sold_date_sk = sale_date.d_date_sk
  JOIN item
    ON catalog_sales.cs_item_sk = item.i_item_sk
  JOIN promotion
    ON catalog_sales.cs_promo_sk = promotion.p_promo_sk
  JOIN date_dim AS promo_start
    ON promotion.p_start_date_sk = promo_start.d_date_sk
  JOIN date_dim AS promo_end
    ON promotion.p_end_date_sk = promo_end.d_date_sk
  WHERE sale_date.d_date BETWEEN promo_start.d_date AND promo_end.d_date
    AND promotion.p_discount_active = 'Y'
),
web_sales_promo AS (
  SELECT
    sale_date.d_year AS year,
    item.i_category AS category,
    web_sales.ws_net_profit AS net_profit,
    'web' AS channel
  FROM web_sales
  JOIN date_dim AS sale_date
    ON web_sales.ws_sold_date_sk = sale_date.d_date_sk
  JOIN item
    ON web_sales.ws_item_sk = item.i_item_sk
  JOIN promotion
    ON web_sales.ws_promo_sk = promotion.p_promo_sk
  JOIN date_dim AS promo_start
    ON promotion.p_start_date_sk = promo_start.d_date_sk
  JOIN date_dim AS promo_end
    ON promotion.p_end_date_sk = promo_end.d_date_sk
  WHERE sale_date.d_date BETWEEN promo_start.d_date AND promo_end.d_date
    AND promotion.p_discount_active = 'Y'
)
SELECT
  year,
  category,
  channel,
  SUM(net_profit) AS total_net_profit,
  COUNT(*) AS sales_count
FROM (
  SELECT year, category, net_profit, channel FROM store_sales_promo
  UNION ALL
  SELECT year, category, net_profit, channel FROM catalog_sales_promo
  UNION ALL
  SELECT year, category, net_profit, channel FROM web_sales_promo
) AS combined
GROUP BY year, category, channel
ORDER BY year, category, channel
