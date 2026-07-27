SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    r.r_reason_desc,
    SUM(wr.wr_return_amt) AS total_return_amt,
    AVG(wr.wr_return_quantity) AS avg_return_qty,
    COUNT(DISTINCT wr.wr_order_number) AS distinct_orders,
    CASE
        WHEN SUM(wr.wr_return_amt) > (SELECT AVG(wr2.wr_return_amt) FROM web_returns wr2)
        THEN 'HIGH'
        ELSE 'NORMAL'
    END AS return_level
FROM web_returns wr
JOIN time_dim td
    ON wr.wr_returned_time_sk = td.t_time_sk
JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer c
    ON wp.wp_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND r.r_reason_id = 'AAAAAAAAFAAAAAAA'
  AND wp.wp_autogen_flag = 'N'
  AND wp.wp_rec_start_date >= DATE '1999-01-01'
  AND wp.wp_rec_start_date < DATE '2001-01-01'
GROUP BY
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    r.r_reason_desc
ORDER BY total_return_amt DESC
LIMIT 100
