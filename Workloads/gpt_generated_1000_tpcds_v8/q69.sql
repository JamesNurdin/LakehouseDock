WITH combined AS (
    SELECT
        w.w_warehouse_sk,
        w.w_state,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_ws_profit,
        SUM(cr.cr_net_loss) AS total_cr_loss,
        SUM(ws.ws_net_profit) - SUM(cr.cr_net_loss) AS net_profit
    FROM catalog_returns cr
    JOIN customer_demographics cd
        ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_reason_sk IN (12, 58)
      AND cd.cd_dep_employed_count >= 2
      AND w.w_street_type = 'Avenue'
      AND ws.ws_quantity > 1
    GROUP BY w.w_warehouse_sk, w.w_state, cd.cd_gender
)
SELECT
    CASE WHEN GROUPING(w_state) = 1 THEN 'All States' ELSE w_state END AS state,
    CASE WHEN GROUPING(cd_gender) = 1 THEN 'All Genders' ELSE cd_gender END AS gender,
    SUM(total_ws_profit) AS sum_ws_profit,
    SUM(total_cr_loss) AS sum_cr_loss,
    SUM(net_profit) AS net_profit,
    RANK() OVER (ORDER BY SUM(net_profit) DESC) AS profit_rank
FROM combined
GROUP BY GROUPING SETS (
    (w_state, cd_gender),
    (w_state),
    (cd_gender),
    ()
)
ORDER BY state, gender, profit_rank
