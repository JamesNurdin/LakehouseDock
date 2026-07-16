SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_number,
    dr_return.d_year AS return_year,
    dr_return.d_current_month AS return_month,
    r.r_reason_desc,
    s_info.s_city AS store_city,
    s_info.s_state AS store_state,
    s_info.store_closed_year,
    s_info.store_closed_month,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_quantity) AS total_return_quantity,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned,
    CASE
        WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High Loss'
        WHEN SUM(cr.cr_net_loss) BETWEEN 1000 AND 10000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS net_loss_category,
    SUM(cr.cr_return_amt_inc_tax) - SUM(cr.cr_return_tax) AS net_return_excluding_tax,
    SUM(cr.cr_fee) AS total_fees,
    SUM(cr.cr_store_credit) AS total_store_credit
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim dr_return
    ON cr.cr_returned_date_sk = dr_return.d_date_sk
JOIN date_dim dr_page_start
    ON cp.cp_start_date_sk = dr_page_start.d_date_sk
JOIN date_dim dr_page_end
    ON cp.cp_end_date_sk = dr_page_end.d_date_sk
CROSS JOIN (
    SELECT
        s.s_store_sk,
        s.s_city,
        s.s_state,
        s.s_closed_date_sk,
        ds.d_year AS store_closed_year,
        ds.d_current_month AS store_closed_month
    FROM store s
    JOIN date_dim ds
        ON s.s_closed_date_sk = ds.d_date_sk
) s_info
WHERE dr_return.d_date BETWEEN dr_page_start.d_date AND dr_page_end.d_date
  AND dr_return.d_year BETWEEN 2019 AND 2022
GROUP BY
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_number,
    dr_return.d_year,
    dr_return.d_current_month,
    r.r_reason_desc,
    s_info.s_city,
    s_info.s_state,
    s_info.store_closed_year,
    s_info.store_closed_month
HAVING COUNT(*) > 10
ORDER BY total_net_loss DESC
LIMIT 100
