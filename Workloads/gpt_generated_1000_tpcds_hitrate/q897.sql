WITH high_loss AS (
   SELECT DISTINCT w.w_warehouse_id
   FROM catalog_returns cr
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE cr.cr_net_loss > 200
),
low_loss AS (
   SELECT DISTINCT w.w_warehouse_id
   FROM catalog_returns cr
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   WHERE cr.cr_net_loss < 50
),
filtered AS (
   SELECT
       cr.cr_return_amount,
       cr.cr_net_loss,
       dd.d_year,
       i.i_brand,
       i.i_category,
       sr.sr_return_quantity,
       w.w_warehouse_id,
       w.w_city,
       ws.web_state,
       CASE WHEN cr.cr_net_loss > 200 THEN 'high' ELSE 'low' END AS loss_category,
       ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cr.cr_return_amount DESC) AS rn
   FROM catalog_returns cr
   JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = dd.d_date_sk
   JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
   JOIN web_site ws ON ws.web_open_date_sk = dd.d_date_sk
   WHERE dd.d_year = 2001
     AND i.i_brand = 'BrandX'
     AND sr.sr_return_quantity > 5
     AND w.w_city = 'Oak Ridge'
     AND ws.web_state = 'CA'
     AND cr.cr_net_loss > 100
     AND cr.cr_return_amount > (SELECT AVG(cr2.cr_return_amount) FROM catalog_returns cr2)
)
SELECT
    f.cr_return_amount,
    f.cr_net_loss,
    f.d_year,
    f.i_brand,
    f.i_category,
    f.sr_return_quantity,
    f.w_warehouse_id,
    f.w_city,
    f.web_state,
    f.loss_category,
    f.rn
FROM filtered f
WHERE f.w_warehouse_id IN (
    SELECT w_warehouse_id FROM high_loss
    EXCEPT
    SELECT w_warehouse_id FROM low_loss
)
ORDER BY f.cr_net_loss DESC, f.rn ASC
LIMIT 100
