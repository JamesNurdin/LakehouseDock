SELECT
    d_ret.d_year,
    i.i_category,
    i.i_item_id,
    SUM(wr.wr_return_amt) AS total_return_amt,
    SUM(CASE WHEN d_ret.d_holiday = 'Y' THEN wr.wr_return_amt ELSE 0 END) AS holiday_return_amt,
    SUM(CASE WHEN d_ret.d_holiday <> 'Y' THEN wr.wr_return_amt ELSE 0 END) AS regular_return_amt,
    ws.web_state,
    RANK() OVER (PARTITION BY d_ret.d_year, i.i_category ORDER BY SUM(wr.wr_return_amt) DESC) AS rank_in_category_year,
    DENSE_RANK() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS overall_dense_rank
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN web_site ws
    ON d_ret.d_date_sk >= ws.web_open_date_sk
   AND (ws.web_close_date_sk IS NULL OR d_ret.d_date_sk <= ws.web_close_date_sk)
WHERE d_ret.d_year BETWEEN 2001 AND 2003
GROUP BY d_ret.d_year, i.i_category, i.i_item_id, ws.web_state
HAVING SUM(wr.wr_return_amt) > 0
ORDER BY d_ret.d_year, i.i_category, rank_in_category_year
