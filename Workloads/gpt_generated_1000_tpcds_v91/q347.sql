WITH
catalog_returns_pre AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN LATERAL (
        SELECT cp.cp_description
        FROM catalog_page cp
        WHERE cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    ) AS cp
    WHERE cc.cc_state = 'TX'
      AND td.t_hour BETWEEN 8 AND 20
      AND ib.ib_upper_bound >= 80000
),
store_returns_pre AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer cust ON sr.sr_customer_sk = cust.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE td.t_hour BETWEEN 8 AND 20
      AND ib.ib_upper_bound >= 80000
),
base_returns AS (
    SELECT * FROM catalog_returns_pre
    UNION DISTINCT
    SELECT * FROM store_returns_pre
),
web_returns_pre AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        cd.cd_gender AS gender,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 8 AND 20
),
final_returns AS (
    SELECT * FROM base_returns
    UNION DISTINCT
    SELECT * FROM web_returns_pre
),
final_agg AS (
    SELECT
        reason_desc,
        gender,
        SUM(net_loss) AS total_net_loss
    FROM final_returns
    GROUP BY GROUPING SETS (
        (reason_desc, gender),
        (reason_desc),
        (gender),
        ()
    )
)
SELECT
    COALESCE(reason_desc, 'ALL') AS reason_desc,
    gender,
    total_net_loss,
    DENSE_RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank,
    CASE
        WHEN total_net_loss > 200000 THEN 'Very High'
        WHEN total_net_loss > 100000 THEN 'High'
        WHEN total_net_loss > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category
FROM final_agg
ORDER BY total_net_loss DESC
LIMIT 100
