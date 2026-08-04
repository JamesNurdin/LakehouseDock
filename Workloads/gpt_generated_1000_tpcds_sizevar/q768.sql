WITH
  item_promo_fo AS (
    SELECT
      i.i_item_sk,
      i.i_category,
      i.i_brand,
      i.i_product_name,
      COALESCE(p.p_promo_id, 'NO_PROMO') AS promo_id
    FROM tpcds.item i
    FULL OUTER JOIN tpcds.promotion p
      ON i.i_item_sk = p.p_item_sk
  ),
  sales_agg AS (
    SELECT
      i.i_item_sk,
      (i.i_category || '-' || i.i_brand || '-' || i.promo_id) AS category_brand_promo,
      SUM(cs.cs_ext_sales_price) AS total_sales
    FROM tpcds.catalog_sales cs
    RIGHT OUTER JOIN item_promo_fo i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE
      regexp_like(i.i_product_name, '(?i)premium')
      OR i.i_product_name LIKE '%Special%'
    GROUP BY
      i.i_item_sk,
      i.i_category,
      i.i_brand,
      i.promo_id
  ),
  warehouse_inventory AS (
    SELECT
      w.w_warehouse_sk,
      w.w_city,
      SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM tpcds.inventory inv
    RIGHT OUTER JOIN tpcds.warehouse w
      ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE 'San%'
    GROUP BY w.w_warehouse_sk, w.w_city
  ),
  union_data AS (
    SELECT
      'Item' AS entity_type,
      s.i_item_sk AS entity_id,
      s.category_brand_promo AS description,
      s.total_sales AS metric
    FROM sales_agg s
    UNION DISTINCT
    SELECT
      'Warehouse' AS entity_type,
      wi.w_warehouse_sk AS entity_id,
      wi.w_city AS description,
      wi.total_inventory AS metric
    FROM warehouse_inventory wi
  )
SELECT
  entity_type,
  entity_id,
  description,
  metric,
  rank() OVER (PARTITION BY entity_type ORDER BY metric DESC) AS metric_rank
FROM union_data
ORDER BY entity_type, metric_rank
LIMIT 100
