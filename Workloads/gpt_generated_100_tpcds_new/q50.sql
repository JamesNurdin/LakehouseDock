WITH sampled_store_sales AS (
        SELECT *
        FROM store_sales
        TABLESAMPLE BERNOULLI (10)
    ),
    non_returned_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    )
SELECT
    c.c_customer_id,
    s.s_store_name,
    wp.wp_url,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_sales_price) AS avg_ext_sales_price,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(ws.ws_net_profit) AS max_web_profit
FROM customer c
JOIN catalog_returns cr
    ON cr.cr_returning_customer_sk = c.c_customer_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
    AND cs.cs_order_number = cr.cr_order_number
JOIN sampled_store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
    AND sr.sr_store_sk = s.s_store_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
WHERE
    s.s_number_employees > 250
    AND cr.cr_return_ship_cost > 1000
    AND cd.cd_education_status = 'Advanced Degree'
    AND t.t_hour BETWEEN 9 AND 17
    AND cs.cs_ext_sales_price > (
        SELECT AVG(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
    )
    AND cs.cs_order_number IN (SELECT cs_order_number FROM non_returned_orders)
GROUP BY
    c.c_customer_id,
    s.s_store_name,
    wp.wp_url
ORDER BY total_net_paid DESC
LIMIT 100
