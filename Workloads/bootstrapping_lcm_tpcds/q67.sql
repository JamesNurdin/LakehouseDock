SELECT
    cp.cp_catalog_number,
    cp.cp_department,
    s.s_state,
    d_ret.d_year,
    i.i_category,
    COUNT(*) AS total_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_return_quantity) AS total_return_quantity,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(wr.wr_refunded_cash) AS total_refunded_cash,
    SUM(wr.wr_net_loss) AS total_net_loss,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_amt ELSE 0 END) AS multi_item_return_amount,
    (SUM(wr.wr_net_loss) / NULLIF(SUM(wr.wr_return_amt), 0)) AS net_loss_ratio,
    MIN(d_ret.d_date) AS earliest_return_date,
    MAX(d_ret.d_date) AS latest_return_date,
    MIN(cp.cp_start_date_sk) AS catalog_start_date_sk,
    MAX(cp.cp_end_date_sk) AS catalog_end_date_sk
FROM web_returns wr
JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item i ON wr.wr_item_sk = i.i_item_sk
JOIN store s ON s.s_closed_date_sk = d_ret.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
WHERE d_ret.d_year BETWEEN 2015 AND 2020
GROUP BY
    cp.cp_catalog_number,
    cp.cp_department,
    s.s_state,
    d_ret.d_year,
    i.i_category
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
