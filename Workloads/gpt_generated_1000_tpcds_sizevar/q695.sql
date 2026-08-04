WITH
  base AS (
    SELECT
      ss.ss_item_sk,
      i.i_category,
      i.i_product_name,
      ss.ss_quantity,
      ss.ss_sales_price,
      ss.ss_net_profit,
      ss.ss_promo_sk,
      ss.ss_sold_date_sk,
      -- Correlated scalar subquery: total promotion cost for the promotion used in this sale
      (SELECT SUM(p2.p_cost)
         FROM promotion p2
        WHERE p2.p_promo_sk = ss.ss_promo_sk) AS total_promo_cost,
      CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS quantity_type
    FROM store_sales ss
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
      ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2450822 AND 2451074               -- date range filter
      AND i.i_wholesale_cost > 10                                     -- cost filter
      AND i.i_brand_id IN (1, 2, 3)                                   -- brand filter
      AND p.p_channel_tv = 'N'                                        -- promotion channel filter
      AND p.p_discount_active = 'N'                                   -- promotion discount flag filter
      AND inv.inv_warehouse_sk = 1                                    -- warehouse filter
  ),
  agg_a AS (
    SELECT
      i_category,
      quantity_type,
      COUNT(*) AS cnt_sales,
      SUM(ss_sales_price) AS total_sales,
      AVG(ss_net_profit) AS avg_profit,
      MIN(ss_sales_price) AS min_sales,
      MAX(ss_sales_price) AS max_sales,
      SUM(total_promo_cost) AS sum_promo_cost
    FROM base
    GROUP BY i_category, quantity_type
  ),
  agg_b AS (
    SELECT
      i_category,
      CASE WHEN quantity_type = 'Bulk' THEN 'HighVolume' ELSE 'LowVolume' END AS volume_group,
      COUNT(*) AS cnt_sales,
      SUM(ss_sales_price) AS total_sales
    FROM base
    WHERE ss_net_profit > 0
    GROUP BY i_category, quantity_type
  ),
  union_all AS (
    SELECT i_category, volume_group, cnt_sales, total_sales
    FROM agg_b
    UNION
    SELECT i_category, quantity_type AS volume_group, cnt_sales, total_sales
    FROM agg_a
  )
SELECT i_category, volume_group, cnt_sales, total_sales
FROM union_all
INTERSECT
SELECT i_category, volume_group, cnt_sales, total_sales
FROM agg_b
WHERE total_sales > 1000
LIMIT 100
