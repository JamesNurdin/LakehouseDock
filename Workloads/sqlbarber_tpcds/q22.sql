SELECT
    w.w_warehouse_name,
    SUM(cs.cs_net_paid) AS total_net_paid
FROM catalog_sales cs
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE w.w_state = 'SD'
GROUP BY w.w_warehouse_name
ORDER BY total_net_paid DESC
