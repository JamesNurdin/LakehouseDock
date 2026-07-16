SELECT
    cc.cc_state AS call_center_state,
    i.i_category AS product_category,
    DATE_TRUNC('month', d_ret.d_date) AS return_month,
    SUM(wr.wr_return_amt) AS total_return_amount,
    AVG(wr.wr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY SUM(wr.wr_return_amt) DESC) AS category_rank
FROM web_returns wr
JOIN date_dim d_ret
    ON wr.wr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON wr.wr_item_sk = i.i_item_sk
JOIN call_center cc
    ON d_ret.d_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE d_ret.d_year = 2001
  AND cc.cc_state IN ('TN', 'GA', 'MI')
  AND wp.wp_type = 'product'
GROUP BY
    cc.cc_state,
    i.i_category,
    DATE_TRUNC('month', d_ret.d_date)
HAVING SUM(wr.wr_return_amt) > 5000
ORDER BY
    cc.cc_state,
    total_return_amount DESC
LIMIT 100
