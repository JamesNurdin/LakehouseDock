/*
  Total quantity and net profit per month, item category, promotion and sales channel
  for the year 2001.  The three sales fact tables (store_sales, catalog_sales,
  web_sales) are unified with a UNION ALL and then joined to the shared
  dimension tables.
*/
WITH sales_union AS (
    SELECT
        ss_sold_date_sk AS sold_date_sk,
        ss_item_sk      AS item_sk,
        ss_promo_sk     AS promo_sk,
        ss_quantity     AS quantity,
        ss_net_profit   AS net_profit,
        'store'         AS channel
    FROM store_sales
    UNION ALL
    SELECT
        cs_sold_date_sk,
        cs_item_sk,
        cs_promo_sk,
        cs_quantity,
        cs_net_profit,
        'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_promo_sk,
        ws_quantity,
        ws_net_profit,
        'web' AS channel
    FROM web_sales
)
SELECT
    date_dim.d_year,
    month(date_dim.d_date) AS month,
    item.i_category,
    promotion.p_promo_name,
    sales_union.channel,
    SUM(sales_union.quantity)   AS total_quantity,
    SUM(sales_union.net_profit) AS total_net_profit
FROM sales_union
JOIN date_dim
  ON sales_union.sold_date_sk = date_dim.d_date_sk
JOIN item
  ON sales_union.item_sk = item.i_item_sk
JOIN promotion
  ON sales_union.promo_sk = promotion.p_promo_sk
WHERE date_dim.d_year = 2001
GROUP BY
    date_dim.d_year,
    month(date_dim.d_date),
    item.i_category,
    promotion.p_promo_name,
    sales_union.channel
ORDER BY
    date_dim.d_year,
    month(date_dim.d_date),
    item.i_category,
    promotion.p_promo_name,
    sales_union.channel
