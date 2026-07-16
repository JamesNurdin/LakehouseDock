SELECT
    cc.cc_market_manager,
    cc.cc_class,
    d_open.d_year AS open_year,
    d_closed.d_year AS closed_year,
    COUNT(DISTINCT wr.wr_order_number) AS total_orders,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(cc.cc_sq_ft) AS avg_sq_ft,
    SUM(cc.cc_employees) AS total_employees,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN cd.cd_demo_sk END) AS male_refunded_customers,
    COUNT(DISTINCT CASE WHEN cd.cd_gender = 'F' THEN cd.cd_demo_sk END) AS female_refunded_customers
FROM call_center cc
JOIN date_dim d_open
    ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
    ON cc.cc_closed_date_sk = d_closed.d_date_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_open.d_date_sk
JOIN customer c
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cc.cc_state = 'TN'
  AND d_open.d_year BETWEEN 2000 AND 2005
  AND d_closed.d_year >= 2006
  AND wr.wr_return_amt > 0
GROUP BY cc.cc_market_manager, cc.cc_class, d_open.d_year, d_closed.d_year
HAVING SUM(wr.wr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
