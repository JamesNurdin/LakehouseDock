SELECT
    d_ret.d_year,
    d_ret.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_store_id,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_store_net_loss,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_web_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    ROW_NUMBER() OVER (
        PARTITION BY d_ret.d_year
        ORDER BY (SUM(sr.sr_return_amt) + SUM(wr.wr_return_amt)) DESC
    ) AS rank_by_year_total_return,
    d_cl.d_current_year AS store_closed_year,
    d_cl.d_month_seq AS store_closed_month_seq
FROM date_dim d_ret
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON i.i_item_sk = sr.sr_item_sk
    AND i.i_item_sk = wr.wr_item_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
JOIN date_dim d_cl
    ON s.s_closed_date_sk = d_cl.d_date_sk
WHERE i.i_category IS NOT NULL
GROUP BY
    d_ret.d_year,
    d_ret.d_month_seq,
    i.i_category,
    i.i_brand,
    s.s_store_id,
    d_cl.d_current_year,
    d_cl.d_month_seq
ORDER BY d_ret.d_year, total_return_amt DESC
LIMIT 100
