WITH brand_color_metrics AS (
   SELECT
      item.i_brand,
      item.i_color,
      SUM(catalog_returns.cr_return_amount) AS total_return_amount,
      AVG(catalog_returns.cr_store_credit) AS avg_store_credit,
      COUNT(*) AS return_cnt
   FROM catalog_returns
   JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
   JOIN promotion ON promotion.p_item_sk = item.i_item_sk
   WHERE item.i_brand IN ('importoexporti', 'corpnameless', 'importoscholar')
     AND item.i_color IN ('sienna', 'papaya', 'smoke')
     AND catalog_returns.cr_return_amount > 0
     AND catalog_returns.cr_store_credit >= 0
     AND promotion.p_channel_tv = 'N'
     AND promotion.p_channel_press = 'N'
   GROUP BY item.i_brand, item.i_color
),
brand_color_alt AS (
   SELECT
      item.i_brand,
      item.i_color,
      SUM(catalog_returns.cr_return_amount) AS total_return_amount,
      AVG(catalog_returns.cr_store_credit) AS avg_store_credit,
      COUNT(*) AS return_cnt
   FROM catalog_returns
   JOIN item ON catalog_returns.cr_item_sk = item.i_item_sk
   JOIN promotion ON promotion.p_item_sk = item.i_item_sk
   WHERE item.i_brand NOT IN ('importoexporti')
     AND item.i_color NOT IN ('snow')
     AND catalog_returns.cr_return_amount > 50
     AND catalog_returns.cr_store_credit < 200
     AND promotion.p_channel_tv = 'Y'
     AND promotion.p_channel_press = 'Y'
   GROUP BY item.i_brand, item.i_color
),
unioned AS (
   SELECT i_brand AS brand,
          i_color AS color,
          total_return_amount,
          avg_store_credit
   FROM brand_color_metrics
   UNION ALL
   SELECT i_brand AS brand,
          i_color AS color,
          total_return_amount,
          avg_store_credit
   FROM brand_color_alt
)
SELECT
   brand,
   SUM(total_return_amount) AS sum_return_amount,
   AVG(avg_store_credit) AS avg_store_credit_over_colors,
   COUNT(*) AS distinct_colors
FROM unioned
WHERE total_return_amount > 500
GROUP BY brand
HAVING SUM(total_return_amount) > 1000
ORDER BY sum_return_amount DESC
LIMIT 100
