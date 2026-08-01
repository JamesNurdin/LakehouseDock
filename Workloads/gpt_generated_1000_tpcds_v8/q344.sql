WITH
  sales_agg AS (
    SELECT
      ss_item_sk AS item_sk,
      SUM(ss_quantity) AS total_quantity,
      SUM(ss_ext_sales_price) AS total_sales,
      SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450815 AND 2450830
      AND ss_quantity > 0
    GROUP BY ss_item_sk
  ),
  returns_agg AS (
    SELECT
      cr.cr_item_sk AS item_sk,
      cp.cp_department AS department,
      SUM(cr.cr_return_quantity) AS total_return_qty,
      SUM(cr.cr_return_amount) AS total_return_amount,
      SUM(cr.cr_net_loss) AS total_net_loss
    FROM catalog_returns cr
    JOIN catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cr.cr_store_credit > 20
      AND cr.cr_return_amount > 10
    GROUP BY cr.cr_item_sk, cp.cp_department
  ),
  item_info AS (
    SELECT
      i.i_item_sk,
      i.i_item_id,
      i.i_product_name,
      i.i_category,
      i.i_brand,
      i.i_wholesale_cost,
      i.i_container,
      i.i_brand_id
    FROM item i
    WHERE i.i_wholesale_cost > 5.00
      AND i.i_container = 'Unknown'
      AND i.i_brand = 'Brand#12'
  ),
  promo_agg AS (
    SELECT
      p.p_item_sk AS item_sk,
      COUNT(*) AS promo_count,
      AVG(p.p_cost) AS avg_promo_cost
    FROM promotion p
    WHERE p.p_channel_tv = 'N'
      AND p.p_discount_active = 'Y'
    GROUP BY p.p_item_sk
  ),
  union_set AS (
    SELECT i.i_brand_id AS key_val FROM item i WHERE i.i_brand_id IN (1, 2, 3)
    UNION ALL
    SELECT p.p_promo_sk AS key_val FROM promotion p WHERE p.p_cost > 1000
  ),
  intersect_set AS (
    SELECT i.i_item_sk AS intersect_item_sk FROM item i WHERE i.i_category = 'Sports'
    INTERSECT
    SELECT cr.cr_item_sk FROM catalog_returns cr WHERE cr.cr_return_amount > 50
  )
SELECT
  ii.i_item_id,
  ii.i_product_name,
  ii.i_category,
  sa.total_quantity,
  sa.total_sales,
  ra.total_return_qty,
  ra.total_return_amount,
  (sa.total_net_profit - COALESCE(ra.total_net_loss, 0)) AS net_profit_after_returns,
  ROW_NUMBER() OVER (PARTITION BY ii.i_category ORDER BY sa.total_sales DESC) AS category_rank,
  pa.promo_count,
  (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_item_sk = ii.i_item_sk) AS avg_promo_cost_corr,
  us.key_val AS union_key,
  iset.intersect_item_sk AS intersect_key
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra ON sa.item_sk = ra.item_sk
JOIN item_info ii ON ii.i_item_sk = COALESCE(sa.item_sk, ra.item_sk)
LEFT JOIN promo_agg pa ON pa.item_sk = ii.i_item_sk
LEFT JOIN union_set us ON us.key_val = ii.i_brand_id
LEFT JOIN intersect_set iset ON iset.intersect_item_sk = ii.i_item_sk
WHERE EXISTS (
        SELECT 1 FROM promotion p3
        WHERE p3.p_item_sk = ii.i_item_sk
          AND p3.p_channel_demo = 'N'
      )
ORDER BY sa.total_sales DESC
LIMIT 100
