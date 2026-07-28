WITH base AS (
   SELECT
       cr.cr_item_sk,
       i.i_category,
       i.i_current_price,
       sm.sm_type,
       cr.cr_return_quantity,
       cr.cr_reversed_charge,
       cr.cr_net_loss AS catalog_net_loss,
       wr.wr_return_quantity,
       wr.wr_fee,
       wr.wr_net_loss AS web_net_loss,
       cr.cr_order_number,
       wr.wr_order_number,
       (
           SELECT COUNT(*)
           FROM promotion p2
           WHERE p2.p_item_sk = i.i_item_sk
             AND p2.p_discount_active = 'Y'
       ) AS active_promo_cnt
   FROM catalog_returns cr
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
   JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
   JOIN promotion p ON p.p_item_sk = i.i_item_sk
   WHERE
       cr.cr_reversed_charge > 10
       AND cr.cr_return_quantity <= 5
       AND wr.wr_fee > 5
       AND wr.wr_return_amt_inc_tax < 500
       AND i.i_current_price BETWEEN 10 AND 100
       AND t.t_time BETWEEN 0 AND 20
       AND sm.sm_type = 'AIR'
       AND p.p_discount_active = 'Y'
       AND (
           SELECT COUNT(*)
           FROM promotion p3
           WHERE p3.p_item_sk = i.i_item_sk
       ) > 0
),
per_item AS (
   SELECT
       cr_item_sk,
       i_category,
       SUM(catalog_net_loss) AS total_catalog_loss,
       SUM(web_net_loss) AS total_web_loss,
       COUNT(DISTINCT cr_order_number) AS catalog_orders,
       COUNT(DISTINCT wr_order_number) AS web_orders,
       SUM(active_promo_cnt) AS total_active_promos
   FROM base
   GROUP BY cr_item_sk, i_category
)
SELECT
   i_category,
   AVG(total_catalog_loss) AS avg_catalog_loss,
   AVG(total_web_loss) AS avg_web_loss,
   SUM(catalog_orders) AS total_catalog_orders,
   SUM(web_orders) AS total_web_orders,
   SUM(total_active_promos) AS total_active_promotions,
   COUNT(DISTINCT cr_item_sk) AS distinct_items
FROM per_item
WHERE total_catalog_loss > 0
GROUP BY i_category
HAVING COUNT(DISTINCT cr_item_sk) >= 5
ORDER BY avg_catalog_loss DESC
LIMIT 100
