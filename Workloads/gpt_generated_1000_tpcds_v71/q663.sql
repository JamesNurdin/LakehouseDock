WITH cr_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        MIN(cr.cr_order_number) AS sample_order_number,
        CASE WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 1
      AND cd_ref.cd_gender = 'M'
      AND cd_ref.cd_marital_status = 'M'
      AND cc.cc_state = 'CA'
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        d.d_year
)
SELECT
    ca.cc_name,
    ca.cp_catalog_page_id,
    ca.d_year,
    ca.total_net_loss,
    ca.return_cnt,
    ca.loss_category,
    RANK() OVER (ORDER BY ca.total_net_loss DESC) AS loss_rank,
    SUM(ca.total_net_loss) OVER (PARTITION BY ca.cc_name ORDER BY ca.d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_loss,
    (SELECT AVG(total_net_loss) FROM cr_agg WHERE d_year = ca.d_year) AS avg_year_loss
FROM cr_agg ca
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    JOIN date_dim wd ON wr.wr_returned_date_sk = wd.d_date_sk
    WHERE wr.wr_order_number = ca.sample_order_number
      AND wd.d_year = ca.d_year
)
ORDER BY ca.total_net_loss DESC, ca.cc_name
