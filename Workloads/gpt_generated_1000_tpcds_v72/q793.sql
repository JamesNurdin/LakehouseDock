WITH
  store_part AS (
    SELECT
      i.i_category,
      'store' AS channel,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS txn_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_start_date_sk <= d.d_date_sk
          AND p2.p_end_date_sk >= d.d_date_sk
      )
    GROUP BY i.i_category
  ),
  catalog_part AS (
    SELECT
      i.i_category,
      'catalog' AS channel,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS txn_count
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_start_date_sk <= d.d_date_sk
          AND p2.p_end_date_sk >= d.d_date_sk
      )
    GROUP BY i.i_category
  )
SELECT
  i_category,
  channel,
  total_profit,
  txn_count
FROM store_part
UNION ALL
SELECT
  i_category,
  channel,
  total_profit,
  txn_count
FROM catalog_part
ORDER BY i_category, channel
LIMIT 100
