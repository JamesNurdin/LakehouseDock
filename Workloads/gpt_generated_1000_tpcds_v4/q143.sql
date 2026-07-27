SELECT
    cs.cs_warehouse_sk,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax
FROM catalog_returns cr
JOIN catalog_sales cs
  ON cr.cr_order_number = cs.cs_order_number
WHERE cr.cr_fee > 20
  AND cs.cs_warehouse_sk = 1
GROUP BY cs.cs_warehouse_sk
ORDER BY total_return_amount DESC
