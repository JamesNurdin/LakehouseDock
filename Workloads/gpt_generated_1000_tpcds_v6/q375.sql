WITH joined_returns AS (
   SELECT
       cr.cr_return_quantity,
       cr.cr_return_amount,
       cr.cr_net_loss,
       i.i_category,
       i.i_wholesale_cost,
       sm.sm_ship_mode_id,
       t.t_hour,
       ca_ref.ca_state,
       CASE WHEN i.i_wholesale_cost > 5 THEN 'HighCost' ELSE 'LowCost' END AS cost_category
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   JOIN customer c_ref ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer c_ret ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
   JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
   WHERE t.t_hour BETWEEN 8 AND 17
     AND i.i_wholesale_cost > 1.0
     AND ca_ref.ca_state = 'CA'
),
category_agg AS (
   SELECT
       i_category,
       cost_category,
       SUM(cr_return_amount) AS total_return_amount,
       COUNT(*) AS return_cnt,
       AVG(cr_net_loss) AS avg_net_loss
   FROM joined_returns
   GROUP BY i_category, cost_category
)
SELECT
    i_category,
    cost_category,
    total_return_amount,
    return_cnt,
    avg_net_loss,
    AVG(total_return_amount) OVER () AS avg_total_return_across_categories
FROM category_agg
ORDER BY total_return_amount DESC
LIMIT 100
