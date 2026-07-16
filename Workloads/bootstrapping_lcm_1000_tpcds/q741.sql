SELECT
    cp.cp_department,
    s.s_city,
    d_ret.d_year,
    d_ret.d_quarter_name,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(cr.cr_net_loss) AS total_net_loss,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    COUNT(DISTINCT cp.cp_catalog_page_sk) AS distinct_pages,
    CASE WHEN SUM(cr.cr_net_loss) > 10000 THEN 'High' ELSE 'Low' END AS loss_category,
    SUM(cr.cr_return_amount) / NULLIF(SUM(cr.cr_return_quantity), 0) AS avg_return_per_qty
FROM catalog_returns cr
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d_ret
    ON cr.cr_returned_date_sk = d_ret.d_date_sk
JOIN date_dim d_cp_start
    ON cp.cp_start_date_sk = d_cp_start.d_date_sk
JOIN date_dim d_cp_end
    ON cp.cp_end_date_sk = d_cp_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN date_dim d_ws_close
    ON ws.web_close_date_sk = d_ws_close.d_date_sk
WHERE d_ret.d_date_sk BETWEEN d_cp_start.d_date_sk AND d_cp_end.d_date_sk
  AND d_ws_close.d_date_sk >= d_ret.d_date_sk
GROUP BY
    cp.cp_department,
    s.s_city,
    d_ret.d_year,
    d_ret.d_quarter_name
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 100
