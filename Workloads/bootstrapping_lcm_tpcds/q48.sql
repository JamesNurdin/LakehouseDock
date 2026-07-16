SELECT
    cp.cp_catalog_page_number,
    cp.cp_type,
    cp.cp_description,
    d_end.d_year,
    d_end.d_date AS cp_end_date,
    d_start.d_date AS cp_start_date,
    d_end.d_week_seq AS cp_end_week_seq,
    d_start.d_week_seq AS cp_start_week_seq,
    s.s_store_name,
    s.s_state,
    s.s_market_id,
    s.s_store_id,
    ws.web_name,
    ws.web_city,
    d_web_close.d_date AS web_close_date,
    wr.wr_return_quantity,
    wr.wr_return_amt_inc_tax,
    wr.wr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY wr.wr_net_loss DESC) AS store_return_rank
FROM catalog_page cp
JOIN date_dim d_end
    ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN date_dim d_start
    ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_end.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_end.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d_start.d_date_sk
JOIN date_dim d_web_close
    ON ws.web_close_date_sk = d_web_close.d_date_sk
WHERE d_end.d_year = 2022
ORDER BY store_return_rank, cp.cp_catalog_page_number
LIMIT 100
