SELECT
    w.w_warehouse_name,
    SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(*) AS return_count,
    SUM(cr.cr_net_loss) / SUM(SUM(cr.cr_net_loss)) OVER () * 100 AS pct_of_total_loss,
    CASE
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'Very High'
        WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High'
        WHEN SUM(cr.cr_net_loss) > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_category,
    DENSE_RANK() OVER (ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_dense_rank
FROM catalog_returns cr
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
WHERE d.d_year = 2022
GROUP BY w.w_warehouse_name
ORDER BY total_net_loss DESC
LIMIT 5
