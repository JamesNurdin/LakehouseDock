WITH joined_all AS (
    SELECT
        d.d_date,
        w.w_warehouse_name,
        w.w_state,
        cc.cc_employees,
        cd_ref.cd_gender,
        i.inv_quantity_on_hand,
        t.t_hour,
        cr.cr_net_loss,
        wr.wr_net_loss
    FROM catalog_returns cr
    INNER JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    INNER JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    INNER JOIN customer_demographics cd_ref
        ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    INNER JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    INNER JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN customer_demographics cd_wr
        ON wr.wr_refunded_cdemo_sk = cd_wr.cd_demo_sk
    WHERE d.d_year = 2002                                    -- filter 1: year
      AND w.w_state = 'CA'                                   -- filter 2: state
      AND cc.cc_employees > 150                              -- filter 3: employee count
      AND cd_ref.cd_gender = 'M'                             -- filter 4: gender
      AND i.inv_quantity_on_hand > 0                         -- filter 5: inventory positive
      AND t.t_hour BETWEEN 9 AND 17                          -- filter 6: business hours
      AND NOT EXISTS (
          SELECT 1
          FROM inventory inv_zero
          WHERE inv_zero.inv_warehouse_sk = w.w_warehouse_sk
            AND inv_zero.inv_quantity_on_hand = 0
      )                                                       -- anti‑join: exclude warehouses that ever had zero stock on the same date
)
SELECT
    d_date,
    w_warehouse_name,
    SUM(cr_net_loss) AS total_catalog_loss,
    SUM(wr_net_loss) AS total_web_loss,
    SUM(cr_net_loss) + SUM(wr_net_loss) AS total_combined_loss,
    CASE WHEN SUM(cr_net_loss) + SUM(wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    RANK() OVER (PARTITION BY d_date ORDER BY (SUM(cr_net_loss) + SUM(wr_net_loss)) DESC) AS loss_rank
FROM joined_all
GROUP BY d_date, w_warehouse_name
ORDER BY d_date ASC, loss_rank ASC
LIMIT 100
