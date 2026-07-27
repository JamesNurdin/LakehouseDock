WITH filtered AS (
    SELECT 
        wr.wr_return_amt,
        wr.wr_return_tax,
        c.c_last_name AS c_last_name,
        ca.ca_state AS ca_state
    FROM tpcds.web_returns wr
    JOIN tpcds.date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN tpcds.web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
      AND ca.ca_state = 'CA'
      AND c.c_salutation = 'Mr.'
      AND c.c_birth_month = 7
      AND wp.wp_type = 'Content'
      AND wr.wr_return_amt > 50
)
SELECT 
    c_last_name,
    ca_state,
    SUM(wr_return_amt) AS total_return_amt,
    COUNT(*) AS returns_cnt,
    AVG(wr_return_tax) AS avg_tax
FROM filtered
GROUP BY GROUPING SETS (
    (c_last_name, ca_state),
    (c_last_name),
    (ca_state),
    ()
)
HAVING SUM(wr_return_amt) > 500
ORDER BY total_return_amt DESC, c_last_name, ca_state
LIMIT 100
