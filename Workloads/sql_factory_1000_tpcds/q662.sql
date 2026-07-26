SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    cp.cp_type,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    CASE
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High'
        WHEN SUM(cr.cr_net_loss) > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    DENSE_RANK() OVER (PARTITION BY cp.cp_department ORDER BY SUM(cr.cr_net_loss) DESC) AS dept_rank
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE hd.hd_buy_potential = 'high'
GROUP BY cp.cp_catalog_page_id, cp.cp_department, cp.cp_type
HAVING SUM(cr.cr_return_quantity) > 0
ORDER BY total_net_loss DESC
LIMIT 10
