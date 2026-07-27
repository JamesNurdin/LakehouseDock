WITH returns AS (
   SELECT
       cr.cr_returned_date_sk AS return_date_sk,
       i.i_item_id,
       i.i_product_name,
       SUM(cr.cr_return_amount) AS total_amount
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_education_status = '4 yr Degree'
     AND cr.cr_return_amount > 100
     AND EXISTS (
         SELECT 1
         FROM promotion p
         WHERE p.p_item_sk = cr.cr_item_sk
           AND p.p_discount_active = 'Y'
     )
   GROUP BY cr.cr_returned_date_sk, i.i_item_id, i.i_product_name
),
low_stock AS (
   SELECT
       CAST(NULL AS integer) AS return_date_sk,
       i.i_item_id,
       i.i_product_name,
       SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_amount
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE inv.inv_quantity_on_hand < 50
     AND w.w_city = 'Seattle'
   GROUP BY i.i_item_id, i.i_product_name
)
SELECT return_date_sk,
       i_item_id,
       i_product_name,
       total_amount
FROM returns
UNION ALL
SELECT return_date_sk,
       i_item_id,
       i_product_name,
       total_amount
FROM low_stock
ORDER BY total_amount DESC
LIMIT 100
