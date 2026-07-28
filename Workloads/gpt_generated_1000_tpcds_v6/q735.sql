SELECT
    s.s_store_name,
    d_sales.d_year,
    i.i_category,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(sr.sr_net_loss) AS total_store_returns,
    SUM(wr.wr_net_loss) AS total_web_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
FROM
    store_sales ss
JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
JOIN reason r_web
    ON wr.wr_reason_sk = r_web.r_reason_sk
JOIN date_dim d_web
    ON wr.wr_returned_date_sk = d_web.d_date_sk
JOIN date_dim d_closed
    ON s.s_closed_date_sk = d_closed.d_date_sk
WHERE
    EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_returned_date_sk = d_sales.d_date_sk
          AND wr2.wr_return_quantity > 0
    )
    AND d_sales.d_year = 2001
GROUP BY
    s.s_store_name,
    d_sales.d_year,
    i.i_category
ORDER BY
    total_sales DESC
LIMIT 100
