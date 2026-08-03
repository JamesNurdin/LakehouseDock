WITH catalog_data AS (
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       d.d_year,
       SUM(cr.cr_net_loss) AS total_net_loss,
       CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
       ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(cr.cr_net_loss) DESC) AS rn
   FROM catalog_returns cr
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
   WHERE d.d_quarter_seq = 12
   GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year
),
catalog_with_label AS (
   SELECT
       cd.*,
       wl.warehouse_label
   FROM catalog_data cd
   CROSS JOIN LATERAL (
       SELECT w.w_warehouse_name || ' (' || w.w_zip || ')' AS warehouse_label
       FROM warehouse w
       WHERE w.w_warehouse_id = cd.w_warehouse_id
   ) wl
),
web_data AS (
   SELECT
       w.w_warehouse_id,
       w.w_warehouse_name,
       d.d_year,
       SUM(wr.wr_net_loss) AS total_net_loss,
       CASE WHEN SUM(wr.wr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
       ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(wr.wr_net_loss) DESC) AS rn
   FROM web_returns wr
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
   WHERE d.d_quarter_seq = 12
   GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year
),
web_with_label AS (
   SELECT
       wd.*,
       wl.warehouse_label
   FROM web_data wd
   CROSS JOIN LATERAL (
       SELECT w.w_warehouse_name || ' (' || w.w_zip || ')' AS warehouse_label
       FROM warehouse w
       WHERE w.w_warehouse_id = wd.w_warehouse_id
   ) wl
)
SELECT
   u.w_warehouse_id,
   u.w_warehouse_name,
   u.d_year,
   u.total_net_loss,
   u.loss_category,
   u.rn,
   u.warehouse_label
FROM (
   SELECT w_warehouse_id, w_warehouse_name, d_year, total_net_loss, loss_category, rn, warehouse_label
   FROM catalog_with_label
   UNION
   SELECT w_warehouse_id, w_warehouse_name, d_year, total_net_loss, loss_category, rn, warehouse_label
   FROM web_with_label
) AS u
ORDER BY u.total_net_loss DESC
LIMIT 100
