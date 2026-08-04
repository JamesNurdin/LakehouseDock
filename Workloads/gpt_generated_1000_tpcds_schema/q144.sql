WITH store_part AS (
   SELECT
       ss.ss_sold_date_sk AS sale_date_sk,
       i.i_item_id,
       p.p_promo_name,
       ss.ss_quantity AS quantity,
       ss.ss_ext_sales_price AS total_sales,
       CASE WHEN ss.ss_quantity > 10 THEN 'High' ELSE 'Low' END AS quantity_category,
       'store' AS source
   FROM store_sales ss
   JOIN item i ON ss.ss_item_sk = i.i_item_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   WHERE ss.ss_quantity > 5
),
catalog_part AS (
   SELECT
       cs.cs_sold_date_sk AS sale_date_sk,
       i.i_item_id,
       p.p_promo_name,
       cs.cs_quantity AS quantity,
       cs.cs_ext_sales_price AS total_sales,
       CASE WHEN cs.cs_quantity > 10 THEN 'High' ELSE 'Low' END AS quantity_category,
       'catalog' AS source
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   WHERE cs.cs_net_paid_inc_ship > 2000
)
SELECT
    sale_date_sk,
    i_item_id,
    p_promo_name,
    quantity,
    total_sales,
    quantity_category,
    source,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS row_num,
    SUM(total_sales) OVER (ORDER BY total_sales DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM (
   SELECT * FROM store_part
   UNION ALL
   SELECT * FROM catalog_part
) combined
ORDER BY total_sales DESC
LIMIT 100
