SELECT
    t.t_hour,
    t.t_shift,
    wp.wp_type,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    SUM(wr.wr_return_amt) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    SUM(wr.wr_return_amt) / NULLIF(SUM(wr.wr_return_quantity), 0) AS avg_return_amount_per_item,
    RANK() OVER (ORDER BY SUM(wr.wr_return_amt) DESC) AS return_amount_rank
FROM web_returns wr
JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE t.t_hour BETWEEN 9 AND 17
  AND wp.wp_type IS NOT NULL
  AND wr.wr_return_amt > 0
GROUP BY t.t_hour, t.t_shift, wp.wp_type
HAVING SUM(wr.wr_return_amt) > 1000
ORDER BY total_return_amount DESC
LIMIT 100
