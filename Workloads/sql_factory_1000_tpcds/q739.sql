SELECT
    w.w_warehouse_id,
    w.w_warehouse_name,
    d.d_year,
    d.d_month_seq,
    cd.cd_gender,
    SUM(cr.cr_net_loss) AS total_net_loss,
    RANK() OVER (PARTITION BY d.d_year, d.d_month_seq, cd.cd_gender ORDER BY SUM(cr.cr_net_loss) DESC) AS warehouse_rank,
    ROUND(100.0 * SUM(cr.cr_net_loss) / SUM(SUM(cr.cr_net_loss)) OVER (PARTITION BY d.d_year, d.d_month_seq, cd.cd_gender), 2) AS pct_of_gender_month_total
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
GROUP BY w.w_warehouse_id, w.w_warehouse_name, d.d_year, d.d_month_seq, cd.cd_gender
ORDER BY d.d_year, d.d_month_seq, cd.cd_gender, warehouse_rank
