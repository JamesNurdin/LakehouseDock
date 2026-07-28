WITH
  store_agg AS (
    SELECT
      i.i_item_id AS i_item_id,
      i.i_brand AS i_brand,
      SUM(ss.ss_ext_sales_price) AS sales_amount,
      COUNT(*) AS txn_count,
      d.d_year AS sales_year
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 1912
    GROUP BY i.i_item_id, i.i_brand, d.d_year
  ),
  catalog_agg AS (
    SELECT
      i.i_item_id AS i_item_id,
      i.i_brand AS i_brand,
      SUM(cs.cs_ext_sales_price) AS sales_amount,
      COUNT(*) AS txn_count,
      d.d_year AS sales_year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 1912
    GROUP BY i.i_item_id, i.i_brand, d.d_year
  ),
  combined AS (
    SELECT i_item_id, i_brand, sales_amount, txn_count, sales_year, 'store' AS sales_channel
    FROM store_agg
    UNION ALL
    SELECT i_item_id, i_brand, sales_amount, txn_count, sales_year, 'catalog' AS sales_channel
    FROM catalog_agg
  )
SELECT
  i_item_id,
  i_brand,
  sales_year,
  sales_channel,
  sales_amount,
  txn_count,
  ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY sales_amount DESC) AS sales_rank
FROM combined
ORDER BY sales_year DESC, sales_amount DESC
LIMIT 100
