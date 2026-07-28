WITH per_return AS (
    SELECT
        cc.cc_call_center_id AS call_center_id,
        dd.d_year,
        dd.d_quarter_seq,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(cr.cr_return_quantity) AS avg_quantity
    FROM catalog_returns cr
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN store s ON s.s_closed_date_sk = dd.d_date_sk
    WHERE dd.d_year BETWEEN 2020 AND 2022
      AND cc.cc_state = 'CA'
      AND w.w_city = 'Houston'
      AND c.c_preferred_cust_flag = 'Y'
      AND s.s_state = 'TX'
      AND cc.cc_mkt_id IN (1, 3, 5)
      AND NOT EXISTS (
            SELECT 1
            FROM warehouse w2
            WHERE w2.w_city = s.s_city
              AND w2.w_state = s.s_state
        )
    GROUP BY cc.cc_call_center_id, dd.d_year, dd.d_quarter_seq
)
SELECT
    call_center_id,
    AVG(total_net_loss) AS avg_net_loss_per_quarter,
    SUM(return_cnt) AS total_returns,
    AVG(avg_quantity) AS overall_avg_quantity
FROM per_return
GROUP BY call_center_id
HAVING SUM(return_cnt) > 100
ORDER BY avg_net_loss_per_quarter DESC
LIMIT 100
