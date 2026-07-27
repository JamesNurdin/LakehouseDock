WITH catalog_agg AS (
   SELECT r.r_reason_desc AS reason_desc,
          t.t_hour,
          SUM(cr.cr_net_loss) AS total_net_loss,
          CASE WHEN SUM(cr.cr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
   FROM catalog_returns cr
   JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
   WHERE cr.cr_return_quantity > 1
     AND t.t_hour BETWEEN 8 AND 12
   GROUP BY r.r_reason_desc, t.t_hour
),
web_agg AS (
   SELECT r.r_reason_desc AS reason_desc,
          t.t_hour,
          SUM(wr.wr_net_loss) AS total_net_loss,
          CASE WHEN SUM(wr.wr_net_loss) > 500 THEN 'High' ELSE 'Low' END AS loss_category
   FROM web_returns wr
   JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
   JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE wr.wr_return_quantity > 1
     AND wp.wp_type = 'product'
   GROUP BY r.r_reason_desc, t.t_hour
)
SELECT reason_desc, t_hour, total_net_loss, loss_category
FROM catalog_agg
UNION ALL
SELECT reason_desc, t_hour, total_net_loss, loss_category
FROM web_agg
ORDER BY total_net_loss DESC
LIMIT 100
