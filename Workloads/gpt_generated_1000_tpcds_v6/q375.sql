WITH avg_item_loss AS (
    SELECT sr_item_sk,
           AVG(sr_net_loss) AS avg_net_loss
    FROM store_returns
    GROUP BY sr_item_sk
),
daily_loss AS (
    SELECT d.d_date,
           cc.cc_name,
           inv.inv_item_sk,
           cc.cc_state,
           i.avg_net_loss,
           SUM(sr.sr_return_quantity) AS total_return_qty,
           SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    LEFT JOIN inventory inv
      ON inv.inv_date_sk = d.d_date_sk
     AND inv.inv_quantity_on_hand > 500
    LEFT JOIN call_center cc
      ON cc.cc_closed_date_sk = d.d_date_sk
     AND cc.cc_state = 'CA'
    JOIN avg_item_loss i
      ON sr.sr_item_sk = i.sr_item_sk
    WHERE d.d_current_month = 'Y'
      AND d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
    GROUP BY d.d_date,
             cc.cc_name,
             inv.inv_item_sk,
             cc.cc_state,
             i.avg_net_loss
)
SELECT d_date,
       cc_name,
       inv_item_sk,
       total_return_qty,
       total_net_loss,
       CASE WHEN total_net_loss > avg_net_loss * 1.5 THEN 'High Loss' ELSE 'Normal Loss' END AS loss_category,
       RANK() OVER (PARTITION BY d_date ORDER BY total_net_loss DESC) AS loss_rank,
       COALESCE(cc_name, 'No Call Center') AS cc_name_coalesce
FROM daily_loss
ORDER BY d_date DESC,
         loss_rank
LIMIT 100
