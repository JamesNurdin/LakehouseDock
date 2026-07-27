WITH agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_manager,
        cp.cp_department,
        ca.ca_state,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cc.cc_manager IN ('Wayne Ray', 'Ryan Burchett')
      AND cp.cp_catalog_page_number BETWEEN 5 AND 20
      AND ca.ca_state = 'CA'
      AND cr.cr_return_amount > 500
    GROUP BY cc.cc_call_center_id, cc.cc_manager, cp.cp_department, ca.ca_state
)
SELECT
    agg.cc_call_center_id,
    agg.cc_manager,
    agg.cp_department,
    agg.ca_state,
    agg.total_return_amount,
    agg.total_net_loss,
    agg.return_cnt,
    (SELECT avg(cr_return_amount) FROM tpcds.catalog_returns) AS overall_avg_return_amount,
    RANK() OVER (PARTITION BY agg.cp_department ORDER BY agg.total_return_amount DESC) AS dept_return_rank,
    SUM(agg.total_return_amount) OVER (PARTITION BY agg.cp_department ORDER BY agg.total_return_amount DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_dept_return
FROM agg
ORDER BY agg.total_return_amount DESC
LIMIT 100
