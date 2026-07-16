SELECT
    s.s_market_id,
    s.s_market_desc,
    cp.cp_type,
    cp.cp_department,
    d_ret.d_year,
    d_ret.d_month_seq,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_tickets,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr.sr_return_amt - sr.sr_return_tax) AS net_store_return_ex_tax,
    SUM(wr.wr_return_amt - wr.wr_return_tax) AS net_web_return_ex_tax,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    AVG(sr.sr_return_amt) AS avg_store_return_amt,
    AVG(wr.wr_return_amt) AS avg_web_return_amt,
    SUM(CASE WHEN sr.sr_return_quantity > 1 THEN sr.sr_return_amt ELSE 0 END) AS multi_item_store_return_amt,
    SUM(CASE WHEN wr.wr_return_quantity > 1 THEN wr.wr_return_amt ELSE 0 END) AS multi_item_web_return_amt,
    ROUND(
        CASE WHEN SUM(wr.wr_return_amt) = 0 THEN NULL
        ELSE SUM(sr.sr_return_amt) / SUM(wr.wr_return_amt) END,
        2
    ) AS store_to_web_return_ratio
FROM
    store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_closed ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d_ret.d_date_sk
    CROSS JOIN catalog_page cp
    JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
WHERE
    d_ret.d_year BETWEEN 2019 AND 2021
    AND s.s_closed_date_sk > sr.sr_returned_date_sk
    AND d_ret.d_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    AND cp.cp_type IS NOT NULL
GROUP BY
    s.s_market_id,
    s.s_market_desc,
    cp.cp_type,
    cp.cp_department,
    d_ret.d_year,
    d_ret.d_month_seq
HAVING
    SUM(sr.sr_return_amt) > 0
ORDER BY
    total_store_return_amt DESC
LIMIT 100
