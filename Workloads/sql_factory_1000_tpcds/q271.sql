WITH returns_by_cc AS (
    SELECT
        cc.cc_city,
        cc.cc_name,
        d_open.d_date AS open_date,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM call_center cc
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d_open.d_date_sk
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year BETWEEN 2019 AND 2021
    GROUP BY cc.cc_city, cc.cc_name, d_open.d_date
)
SELECT
    cc_city,
    cc_name,
    open_date,
    total_return_amt,
    distinct_orders,
    RANK() OVER (PARTITION BY cc_city ORDER BY total_return_amt DESC) AS return_amount_rank,
    CASE
        WHEN total_return_amt > 10000 THEN 'High'
        WHEN total_return_amt BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS return_level
FROM returns_by_cc
WHERE total_return_amt > 0
ORDER BY cc_city, return_amount_rank
