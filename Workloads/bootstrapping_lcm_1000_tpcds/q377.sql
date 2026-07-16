SELECT
    cp.cp_department,
    cp.cp_type,
    r.r_reason_desc,
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END AS half_year,
    s.s_state,
    d_start.d_date AS catalog_start_date,
    d_end.d_date   AS catalog_end_date,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    SUM(CASE WHEN cr.cr_return_amount > 100 THEN cr.cr_return_amount ELSE 0 END) AS high_value_return_amount,
    COUNT(DISTINCT cr.cr_item_sk) AS distinct_items_returned
FROM catalog_returns cr
JOIN catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r          ON cr.cr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_start  ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end    ON cp.cp_end_date_sk   = d_end.d_date_sk
JOIN store s           ON s.s_closed_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
  AND cp.cp_type IN ('Online', 'Print')
GROUP BY
    cp.cp_department,
    cp.cp_type,
    r.r_reason_desc,
    d_ret.d_year,
    CASE WHEN d_ret.d_month_seq <= 6 THEN 'H1' ELSE 'H2' END,
    s.s_state,
    d_start.d_date,
    d_end.d_date
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
