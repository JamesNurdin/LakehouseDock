WITH sales AS (
   SELECT
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_warehouse_sk,
       cs.cs_ship_mode_sk,
       cs.cs_item_sk,
       cs.cs_order_number,
       cs.cs_ext_sales_price,
       cs.cs_quantity,
       p.p_promo_name,
       sm.sm_contract,
       cp.cp_type,
       td.t_time
   FROM catalog_sales cs
   JOIN promotion p          ON cs.cs_promo_sk   = p.p_promo_sk
   JOIN ship_mode sm         ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN time_dim td          ON cs.cs_sold_time_sk = td.t_time_sk
   WHERE regexp_like(sm.sm_contract, '^...T')
     AND cp.cp_type LIKE 'C%'
     AND p.p_channel_event = 'N'
),
returns AS (
   SELECT
       cr.cr_item_sk,
       cr.cr_order_number
   FROM catalog_returns cr
   WHERE cr.cr_return_quantity > 0
),
sold_not_returned AS (
   SELECT cs_item_sk FROM sales
   EXCEPT
   SELECT cr_item_sk FROM returns
),
warehouse_agg AS (
   SELECT
       w.w_warehouse_id,
       w.w_city,
       COUNT(DISTINCT s.cs_item_sk)        AS distinct_items_sold,
       SUM(DISTINCT s.cs_ext_sales_price)  AS distinct_sales_sum,
       SUM(s.cs_ext_sales_price)           AS total_sales,
       SUM(s.cs_quantity)                  AS total_quantity
   FROM sales s
   JOIN sold_not_returned snr ON s.cs_item_sk = snr.cs_item_sk
   JOIN warehouse w           ON s.cs_warehouse_sk = w.w_warehouse_sk
   GROUP BY w.w_warehouse_id, w.w_city
)
SELECT
   wa.w_warehouse_id,
   wa.w_city,
   wa.distinct_items_sold,
   wa.distinct_sales_sum,
   wa.total_sales,
   wa.total_quantity,
   LAG(wa.total_sales) OVER (PARTITION BY wa.w_warehouse_id ORDER BY wa.total_sales) AS prev_total_sales,
   CONCAT('Warehouse ', wa.w_warehouse_id, ' - ', wa.w_city) AS warehouse_desc,
   SUBSTRING(wa.w_city FROM 1 FOR 3) AS city_prefix
FROM warehouse_agg wa
WHERE CONCAT('Warehouse ', wa.w_warehouse_id, ' - ', wa.w_city) LIKE '%Warehouse%'
ORDER BY wa.total_sales DESC
LIMIT 100
