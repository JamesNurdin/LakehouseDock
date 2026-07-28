WITH base_data AS (
   SELECT
       w.w_warehouse_id,
       w.w_state,
       p.p_promo_name,
       p.p_discount_active,
       d.d_year,
       cs.cs_item_sk,
       cs.cs_quantity,
       cs.cs_net_paid,
       cr.cr_return_amount,
       wr.wr_return_amt,
       inv.inv_quantity_on_hand
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        AND cr.cr_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
),
agg AS (
   SELECT
       w_warehouse_id,
       w_state,
       p_promo_name,
       d_year,
       SUM(cs_net_paid) AS total_sales,
       SUM(cs_quantity) AS total_quantity,
       SUM(COALESCE(cr_return_amount, 0) + COALESCE(wr_return_amt, 0)) AS total_returns,
       SUM(inv_quantity_on_hand) AS total_inventory,
       COUNT(DISTINCT cs_item_sk) AS distinct_items_sold
   FROM base_data
   WHERE d_year = 2001
     AND w_state = 'CA'
     AND p_discount_active = 'Y'
     AND cs_quantity > 5
   GROUP BY GROUPING SETS (
       (w_warehouse_id, w_state, p_promo_name, d_year),
       (w_warehouse_id, w_state, d_year),
       (d_year),
       ()
   )
)
SELECT
   COALESCE(w_warehouse_id, 'ALL_WAREHOUSES') AS warehouse_id,
   COALESCE(w_state, 'ALL_STATES') AS state,
   COALESCE(p_promo_name, 'ALL_PROMOS') AS promo_name,
   COALESCE(d_year, -1) AS year,
   total_sales,
   total_quantity,
   total_returns,
   total_inventory,
   distinct_items_sold,
   AVG(total_sales) OVER (PARTITION BY w_warehouse_id) AS avg_sales_per_warehouse,
   (SELECT COUNT(DISTINCT p2.p_promo_name) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS active_promo_count
FROM agg
ORDER BY warehouse_id, total_sales DESC
LIMIT 100
