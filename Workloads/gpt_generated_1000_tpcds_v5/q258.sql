WITH sales_base AS (
   SELECT cs.cs_order_number,
          cs.cs_net_paid,
          cs.cs_item_sk,
          cs.cs_ship_mode_sk,
          cs.cs_sold_time_sk
   FROM catalog_sales cs
)
SELECT
   sm_sales.sm_ship_mode_id            AS ship_mode_id,
   td_sales.t_hour                     AS sale_hour,
   COUNT(DISTINCT sb.cs_order_number)  AS orders_count,
   SUM(sb.cs_net_paid)                 AS total_net_paid,
   SUM(cr.cr_net_loss)                 AS total_return_loss,
   SUM(cr2.cr_net_loss)                AS total_return_loss_2,
   SUM(wr.wr_net_loss)                 AS total_web_return_loss,
   CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'HIGH' ELSE 'LOW' END AS return_loss_category
FROM sales_base sb
JOIN ship_mode sm_sales
  ON sb.cs_ship_mode_sk = sm_sales.sm_ship_mode_sk                                 -- join 1
JOIN time_dim td_sales
  ON sb.cs_sold_time_sk = td_sales.t_time_sk                                        -- join 2
JOIN catalog_returns cr
  ON cr.cr_item_sk = sb.cs_item_sk                                                  -- join 3
JOIN catalog_returns cr2
  ON cr2.cr_order_number = sb.cs_order_number                                      -- join 4
JOIN ship_mode sm_return
  ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk                                -- join 5
JOIN time_dim td_return
  ON cr.cr_returned_time_sk = td_return.t_time_sk                                   -- join 6
JOIN web_returns wr
  ON wr.wr_returned_time_sk = td_sales.t_time_sk                                    -- join 7
JOIN time_dim td_web
  ON wr.wr_returned_time_sk = td_web.t_time_sk                                      -- join 8
JOIN ship_mode sm_return2
  ON cr2.cr_ship_mode_sk = sm_return2.sm_ship_mode_sk                               -- join 9
GROUP BY sm_sales.sm_ship_mode_id, td_sales.t_hour
ORDER BY total_net_paid DESC
LIMIT 100
