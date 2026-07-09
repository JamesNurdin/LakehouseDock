WITH return_agg AS (
    SELECT
        cc.cc_company_name,
        cp.cp_department,
        r.r_reason_desc,
        hd.hd_buy_potential,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        AVG(cr.cr_return_quantity) AS avg_return_quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_rec_end_date >= DATE '2000-01-01'
      AND cc.cc_class = 'large'
    GROUP BY cc.cc_company_name, cp.cp_department, r.r_reason_desc, hd.hd_buy_potential
    HAVING SUM(cr.cr_return_amount) > 5000
)
SELECT
    ra.*,
    RANK() OVER (PARTITION BY ra.cc_company_name ORDER BY ra.total_return_amount DESC) AS dept_return_rank,
    ra.total_return_amount / SUM(ra.total_return_amount) OVER () AS pct_of_total_return
FROM return_agg ra
ORDER BY ra.total_return_amount DESC
LIMIT 100
