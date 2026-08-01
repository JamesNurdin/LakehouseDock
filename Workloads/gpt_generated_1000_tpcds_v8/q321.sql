WITH sales_enriched AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_quantity,
       cs.cs_net_paid,
       i.i_category,
       w.w_warehouse_name,
       p.p_promo_name,
       t.t_hour,
       lc.avg_cost AS avg_promo_cost
   FROM catalog_sales cs
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   CROSS JOIN LATERAL (
       SELECT avg(p2.p_cost) AS avg_cost
       FROM promotion p2
       WHERE p2.p_item_sk = cs.cs_item_sk
   ) lc
   WHERE cs.cs_sold_date_sk BETWEEN 2450118 AND 2450581
),
combined_sales AS (
   SELECT
       se.cs_item_sk,
       se.cs_order_number,
       se.cs_sold_date_sk,
       se.cs_quantity,
       se.cs_net_paid,
       se.i_category,
       se.w_warehouse_name,
       se.p_promo_name,
       se.t_hour,
       se.avg_promo_cost
   FROM sales_enriched se
   WHERE EXISTS (
       SELECT 1
       FROM catalog_returns cr
       WHERE cr.cr_order_number = se.cs_order_number
         AND cr.cr_return_quantity > 0
   )
   UNION ALL
   SELECT
       i.i_item_sk AS cs_item_sk,
       NULL AS cs_order_number,
       NULL AS cs_sold_date_sk,
       0 AS cs_quantity,
       0.0 AS cs_net_paid,
       i.i_category,
       w.w_warehouse_name,
       NULL AS p_promo_name,
       NULL AS t_hour,
       NULL AS avg_promo_cost
   FROM inventory inv
   JOIN item i ON inv.inv_item_sk = i.i_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE NOT EXISTS (
       SELECT 1
       FROM sales_enriched se2
       WHERE se2.cs_item_sk = i.i_item_sk
   )
),
returns_data AS (
   SELECT
       cr.cr_item_sk,
       cr.cr_order_number,
       cr.cr_returned_date_sk,
       cr.cr_return_quantity,
       cr.cr_return_amount
   FROM catalog_returns cr
   WHERE cr.cr_returned_date_sk BETWEEN 2450118 AND 2450581
),
full_combined AS (
   SELECT
       cs.cs_item_sk,
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_quantity,
       cs.cs_net_paid,
       cs.i_category,
       cs.w_warehouse_name,
       cs.p_promo_name,
       cs.t_hour,
       cs.avg_promo_cost,
       rd.cr_returned_date_sk,
       rd.cr_return_quantity,
       rd.cr_return_amount
   FROM combined_sales cs
   FULL OUTER JOIN returns_data rd
     ON cs.cs_item_sk = rd.cr_item_sk
   WHERE NOT EXISTS (
       SELECT 1
       FROM web_returns wr
       WHERE wr.wr_item_sk = cs.cs_item_sk
   )
)
SELECT *
FROM full_combined
EXCEPT
SELECT
   sr.sr_item_sk AS cs_item_sk,
   sr.sr_ticket_number AS cs_order_number,
   NULL AS cs_sold_date_sk,
   NULL AS cs_quantity,
   NULL AS cs_net_paid,
   NULL AS i_category,
   NULL AS w_warehouse_name,
   NULL AS p_promo_name,
   NULL AS t_hour,
   NULL AS avg_promo_cost,
   NULL AS cr_returned_date_sk,
   NULL AS cr_return_quantity,
   NULL AS cr_return_amount
FROM store_returns sr
WHERE sr.sr_returned_date_sk BETWEEN 2450118 AND 2450581
ORDER BY cs_item_sk, cs_order_number NULLS LAST
