WITH
date_filtered AS (
  SELECT d_date_sk,
         d_date,
         d_year
  FROM date_dim
  WHERE d_year IN (2002, 2003)
),
item_details AS (
  SELECT i_item_sk,
         i_item_id,
         i_product_name,
         i_brand,
         i_color,
         i_current_price,
         CONCAT(i_brand, ' ', i_product_name) AS full_name,
         CASE
           WHEN i_current_price > 100 THEN 'High'
           WHEN i_current_price BETWEEN 50 AND 100 THEN 'Medium'
           ELSE 'Low'
         END AS price_category
  FROM item
),
sales_union AS (
  SELECT 'store' AS channel,
         ss_sold_date_sk AS sales_date_sk,
         ss_item_sk AS item_sk,
         ss_net_paid AS net_paid,
         ss_net_profit AS net_profit,
         ss_quantity AS quantity,
         ss_ext_discount_amt AS discount_amt
  FROM store_sales
  UNION ALL
  SELECT 'catalog' AS channel,
         cs_sold_date_sk AS sales_date_sk,
         cs_item_sk AS item_sk,
         cs_net_paid AS net_paid,
         cs_net_profit AS net_profit,
         cs_quantity AS quantity,
         cs_ext_discount_amt AS discount_amt
  FROM catalog_sales
  UNION ALL
  SELECT 'web' AS channel,
         ws_sold_date_sk AS sales_date_sk,
         ws_item_sk AS item_sk,
         ws_net_paid AS net_paid,
         ws_net_profit AS net_profit,
         ws_quantity AS quantity,
         ws_ext_discount_amt AS discount_amt
  FROM web_sales
),
sales_agg_base AS (
  SELECT channel,
         sales_date_sk,
         item_sk,
         SUM(net_paid) AS total_sales,
         SUM(net_profit) AS total_profit,
         SUM(quantity) AS total_quantity,
         SUM(discount_amt) AS total_discount,
         COUNT(*) AS txn_count
  FROM sales_union
  GROUP BY channel, sales_date_sk, item_sk
),
sales_agg AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY channel, sales_date_sk ORDER BY total_sales DESC) AS sales_rank
  FROM sales_agg_base
),
top_sales AS (
  SELECT *
  FROM sales_agg
  WHERE sales_rank <= 5
),
unsold_items AS (
  SELECT d.d_date_sk AS sales_date_sk,
         i.i_item_sk AS item_sk,
         'store' AS channel
  FROM date_filtered d
  CROSS JOIN item_details i
  WHERE NOT EXISTS (
    SELECT 1 FROM sales_agg_base s
    WHERE s.sales_date_sk = d.d_date_sk
      AND s.item_sk = i.i_item_sk
      AND s.channel = 'store'
  )
  UNION ALL
  SELECT d.d_date_sk,
         i.i_item_sk,
         'catalog'
  FROM date_filtered d
  CROSS JOIN item_details i
  WHERE NOT EXISTS (
    SELECT 1 FROM sales_agg_base s
    WHERE s.sales_date_sk = d.d_date_sk
      AND s.item_sk = i.i_item_sk
      AND s.channel = 'catalog'
  )
  UNION ALL
  SELECT d.d_date_sk,
         i.i_item_sk,
         'web'
  FROM date_filtered d
  CROSS JOIN item_details i
  WHERE NOT EXISTS (
    SELECT 1 FROM sales_agg_base s
    WHERE s.sales_date_sk = d.d_date_sk
      AND s.item_sk = i.i_item_sk
      AND s.channel = 'web'
  )
),
combined AS (
  SELECT
    sales_date_sk,
    channel,
    item_sk,
    total_sales,
    total_profit,
    total_quantity,
    total_discount,
    txn_count,
    sales_rank
  FROM top_sales
  UNION ALL
  SELECT
    sales_date_sk,
    channel,
    item_sk,
    0.0 AS total_sales,
    0.0 AS total_profit,
    0 AS total_quantity,
    0.0 AS total_discount,
    0 AS txn_count,
    NULL AS sales_rank
  FROM unsold_items
),
promo_active AS (
  SELECT p.p_item_sk AS item_sk,
         d.d_date_sk AS date_sk,
         1 AS promo_flag
  FROM promotion p
  JOIN date_filtered d
    ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
),
store_web_common AS (
  SELECT ss_sold_date_sk AS sales_date_sk, ss_item_sk AS item_sk
  FROM store_sales
  INTERSECT
  SELECT ws_sold_date_sk, ws_item_sk
  FROM web_sales
),
final AS (
  SELECT
    COALESCE(df.sales_date_sk, pa.date_sk) AS sales_date_sk,
    d.d_date AS sale_date,
    COALESCE(df.channel, 'PROMO_ONLY') AS channel,
    ii.full_name,
    ii.i_item_id,
    ii.i_brand,
    ii.i_color,
    COALESCE(df.total_sales, 0.0) AS total_sales,
    COALESCE(df.total_profit, 0.0) AS total_profit,
    CASE WHEN COALESCE(df.total_sales, 0.0) > 0 THEN COALESCE(df.total_profit, 0.0) / COALESCE(df.total_sales, 0.0) ELSE NULL END AS profit_margin,
    COALESCE(df.total_quantity, 0) AS total_quantity,
    COALESCE(df.total_discount, 0.0) AS total_discount,
    COALESCE(df.txn_count, 0) AS txn_count,
    df.sales_rank,
    COALESCE(pa.promo_flag, 0) AS promo_active_flag,
    CASE WHEN cw.sales_date_sk IS NOT NULL THEN 1 ELSE 0 END AS common_flag,
    CONCAT(ii.full_name, ' - ', COALESCE(df.channel, 'PROMO_ONLY')) AS item_channel_label,
    (SELECT MAX(cr_return_amount)
     FROM catalog_returns cr
     WHERE cr.cr_item_sk = ii.i_item_sk
       AND cr.cr_returned_date_sk = COALESCE(df.sales_date_sk, pa.date_sk)) AS max_catalog_return_amount,
    (SELECT COUNT(*)
     FROM web_returns wr
     WHERE wr.wr_item_sk = ii.i_item_sk
       AND wr.wr_returned_date_sk = COALESCE(df.sales_date_sk, pa.date_sk)) AS web_return_cnt,
    AVG(COALESCE(df.total_sales, 0.0)) OVER (PARTITION BY COALESCE(df.channel, 'PROMO_ONLY'), COALESCE(df.item_sk, pa.item_sk) ORDER BY d.d_date ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING) AS avg_sales_last_7d,
    SUM(COALESCE(df.total_sales, 0.0)) OVER (PARTITION BY COALESCE(df.channel, 'PROMO_ONLY') ORDER BY d.d_date ROWS UNBOUNDED PRECEDING) AS cumulative_sales_channel,
    ii.price_category
  FROM combined df
  FULL OUTER JOIN promo_active pa
    ON df.item_sk = pa.item_sk AND df.sales_date_sk = pa.date_sk
  LEFT JOIN date_filtered d
    ON d.d_date_sk = COALESCE(df.sales_date_sk, pa.date_sk)
  LEFT JOIN item_details ii
    ON ii.i_item_sk = COALESCE(df.item_sk, pa.item_sk)
  LEFT JOIN store_web_common cw
    ON cw.sales_date_sk = COALESCE(df.sales_date_sk, pa.date_sk)
    AND cw.item_sk = COALESCE(df.item_sk, pa.item_sk)
  WHERE (ii.price_category = 'High' OR ii.price_category = 'Medium')
    AND (COALESCE(df.sales_rank, 9999) <= 10 OR df.sales_rank IS NULL)
    AND (ii.i_color LIKE '%R%' OR ii.i_color IS NULL)
    AND d.d_year = 2002
)
SELECT *
FROM final
ORDER BY sale_date DESC, total_sales DESC
LIMIT 200
