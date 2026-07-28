WITH warehouse_return_stats AS (
   SELECT
       cr.cr_warehouse_sk,
       AVG(cr.cr_net_loss) AS avg_warehouse_net_loss
   FROM catalog_returns cr
   GROUP BY cr.cr_warehouse_sk
),
base_agg AS (
   SELECT
       d_ret.d_year,
       ca_ref.ca_state,
       w.w_warehouse_name,
       SUM(cr.cr_net_loss) AS total_net_loss,
       COUNT(*) AS return_cnt,
       AVG(cr.cr_return_amount) AS avg_return_amount,
       MAX(warehouse_return_stats.avg_warehouse_net_loss) AS avg_warehouse_net_loss
   FROM catalog_returns cr
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
   JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
       AND ws.ws_warehouse_sk = w.w_warehouse_sk
       AND ws.ws_ship_date_sk = d_ret.d_date_sk
   LEFT JOIN warehouse_return_stats ON warehouse_return_stats.cr_warehouse_sk = w.w_warehouse_sk
   WHERE d_ret.d_year = 2001
     AND ca_ref.ca_state = 'CA'
     AND ws.ws_ext_ship_cost > 2000
   GROUP BY GROUPING SETS (
       (d_ret.d_year, ca_ref.ca_state, w.w_warehouse_name),
       (d_ret.d_year, ca_ref.ca_state),
       (d_ret.d_year),
       ()
   )
   HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT
   d_year,
   ca_state,
   w_warehouse_name,
   total_net_loss,
   return_cnt,
   avg_return_amount,
   avg_warehouse_net_loss,
   RANK() OVER (PARTITION BY d_year ORDER BY total_net_loss DESC) AS loss_rank,
   CASE
       WHEN total_net_loss > COALESCE(avg_warehouse_net_loss, 0) * 2 THEN 'High'
       ELSE 'Normal'
   END AS loss_category
FROM base_agg
ORDER BY d_year, loss_rank
LIMIT 100
