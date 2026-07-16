SELECT
    d.d_year * 100 + d.d_moy AS year_month,
    (d.d_year * 100 + d.d_moy) / 100 AS year,
    (d.d_year * 100 + d.d_moy) % 100 AS month,
    i.i_category,
    i.i_brand,
    CASE
        WHEN r.r_reason_desc LIKE '%defect%' THEN 'Defect'
        WHEN r.r_reason_desc LIKE '%damage%' THEN 'Damaged'
        ELSE 'Other'
    END AS reason_group,
    CASE
        WHEN cr.cr_net_loss > 0 THEN 'Loss'
        ELSE 'Profit'
    END AS loss_category,
    COUNT(*) AS return_cnt,
    SUM(cr.cr_return_quantity) AS total_qty,
    SUM(cr.cr_return_amount) AS total_return_amt,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    SUM(cr.cr_fee) AS total_fees,
    SUM(cr.cr_return_ship_cost) AS total_ship_cost,
    SUM(cr.cr_store_credit) AS total_store_credit,
    SUM(cr.cr_return_tax) AS total_tax,
    SUM(cr.cr_return_amt_inc_tax) AS total_inc_tax,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS distinct_returning_customers,
    COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers
FROM catalog_returns cr
JOIN date_dim d
    ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2015 AND 2020
  AND i.i_category IN ('Electronics', 'Furniture', 'Office')
  AND s.s_state = 'CA'
GROUP BY
    d.d_year * 100 + d.d_moy,
    i.i_category,
    i.i_brand,
    CASE
        WHEN r.r_reason_desc LIKE '%defect%' THEN 'Defect'
        WHEN r.r_reason_desc LIKE '%damage%' THEN 'Damaged'
        ELSE 'Other'
    END,
    CASE
        WHEN cr.cr_net_loss > 0 THEN 'Loss'
        ELSE 'Profit'
    END
HAVING COUNT(*) > 10
ORDER BY total_return_amt DESC
LIMIT 100
