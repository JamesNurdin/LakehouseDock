SELECT
    cp.cp_catalog_number,
    cp.cp_department,
    cp.cp_type,
    s.s_store_id,
    s.s_market_id,
    (d_start.d_year * 100 + d_start.d_month_seq) AS year_month,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_ticket_cnt,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    AVG(sr.sr_net_loss) AS avg_store_net_loss,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_order_cnt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    AVG(wr.wr_net_loss) AS avg_web_net_loss,
    CASE
        WHEN SUM(sr.sr_return_amt) > 0 THEN SUM(wr.wr_return_amt) / SUM(sr.sr_return_amt)
        ELSE NULL
    END AS web_to_store_return_ratio
FROM catalog_page cp
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_start.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_start.d_date_sk
   AND sr.sr_store_sk = s.s_store_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_start.d_date_sk
GROUP BY
    cp.cp_catalog_number,
    cp.cp_department,
    cp.cp_type,
    s.s_store_id,
    s.s_market_id,
    (d_start.d_year * 100 + d_start.d_month_seq)
HAVING
    SUM(sr.sr_return_amt) > 1000
