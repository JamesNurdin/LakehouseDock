WITH sales_agg AS (
   SELECT
      cs.cs_warehouse_sk,
      cs.cs_ship_mode_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      SUM(cs.cs_ext_sales_price)               AS total_sales,
      SUM(cs.cs_quantity)                      AS total_qty,
      COUNT(*)                                 AS order_cnt
   FROM catalog_sales cs
   JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
   JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   WHERE hd.hd_dep_count >= 1                                   -- predicate 1
     AND hd.hd_vehicle_count >= 0                               -- predicate 2
     AND sm.sm_ship_mode_id = 'AAAAAAAABAAAAAAA'                -- predicate 3
   GROUP BY cs.cs_warehouse_sk,
            cs.cs_ship_mode_sk,
            cs.cs_item_sk,
            cs.cs_promo_sk
),
joined_data AS (
   SELECT
      w.w_warehouse_name,
      w.w_city,
      sm.sm_type,
      i.i_brand,
      sa.total_sales,
      sa.total_qty,
      sa.order_cnt,
      sa.total_sales / NULLIF(sa.total_qty, 0) AS avg_price_per_qty
   FROM sales_agg sa
   LEFT JOIN warehouse w
        ON sa.cs_warehouse_sk = w.w_warehouse_sk               -- outer join
   JOIN ship_mode sm
        ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN item i
        ON sa.cs_item_sk = i.i_item_sk
   JOIN promotion p
        ON sa.cs_promo_sk = p.p_promo_sk
   WHERE w.w_county = 'Williamson County'                      -- predicate 4
     AND p.p_discount_active = 'Y'                             -- predicate 5
     AND i.i_brand = 'BrandA'                                   -- predicate 6
)
SELECT
   w_warehouse_name,
   w_city,
   SUM(total_sales)               AS warehouse_sales,
   SUM(total_qty)                 AS warehouse_qty,
   SUM(order_cnt)                 AS total_orders,
   AVG(avg_price_per_qty)         AS avg_price_per_qty,
   COUNT(*)                       AS sku_count
FROM joined_data
GROUP BY w_warehouse_name, w_city
ORDER BY warehouse_sales DESC
LIMIT 100
