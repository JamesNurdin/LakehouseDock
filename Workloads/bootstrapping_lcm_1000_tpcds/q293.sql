SELECT
    (d.d_year * 100 + d.d_month_seq) AS year_month_key,
    d.d_year,
    d.d_month_seq,
    ic.i_category,
    ic.i_brand,
    s.s_state,
    COUNT(*) AS total_returns,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(cr.cr_return_quantity) AS catalog_return_qty,
    SUM(wr.wr_return_quantity) AS web_return_qty,
    AVG(cr.cr_fee) AS avg_catalog_fee,
    AVG(wr.wr_fee) AS avg_web_fee,
    (SUM(cr.cr_return_amount) - SUM(wr.wr_return_amt)) AS net_return_amount_diff,
    CASE
        WHEN SUM(cr.cr_return_amount) > SUM(wr.wr_return_amt) THEN 'Catalog'
        ELSE 'Web'
    END AS higher_return_source,
    MIN(iw.i_color) AS web_item_color_min,
    MAX(iw.i_size) AS web_item_size_max
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item ic ON cr.cr_item_sk = ic.i_item_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN item iw ON wr.wr_item_sk = iw.i_item_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
  AND ic.i_category IS NOT NULL
  AND s.s_state IS NOT NULL
GROUP BY
    (d.d_year * 100 + d.d_month_seq),
    d.d_year,
    d.d_month_seq,
    ic.i_category,
    ic.i_brand,
    s.s_state
HAVING SUM(cr.cr_return_amount) > 0 OR SUM(wr.wr_return_amt) > 0
ORDER BY year_month_key, ic.i_category
LIMIT 100
