SELECT
    w.w_city,
    cd.cd_gender,
    r.r_reason_desc,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    AVG(CASE WHEN cr.cr_fee > 0 THEN cr.cr_fee ELSE 0 END) AS avg_positive_fee,
    MAX(cr.cr_net_loss) AS max_net_loss
FROM catalog_returns cr
JOIN customer_demographics cd
    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
    AND sr.sr_reason_sk = r.r_reason_sk
JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
WHERE w.w_gmt_offset = -7.00
  AND i.inv_item_sk IN (101420, 101425)
  AND cr.cr_fee > 50
GROUP BY w.w_city, cd.cd_gender, r.r_reason_desc
ORDER BY total_catalog_return_amount DESC
LIMIT 100
