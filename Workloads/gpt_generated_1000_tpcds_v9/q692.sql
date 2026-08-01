SELECT
    d.d_year AS year,
    cc.cc_market_manager,
    cc.cc_class,
    ca.ca_state,
    ca.ca_address_sk,
    SUM(s.ss_ext_sales_price) AS total_sales,
    AVG(s.ss_quantity) AS avg_quantity,
    COUNT(DISTINCT s.ss_ticket_number) AS distinct_tickets,
    MIN(s.ss_ext_discount_amt) AS min_discount,
    MAX(s.ss_ext_discount_amt) AS max_discount,
    CASE WHEN SUM(s.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    (SELECT COUNT(*) FROM store_sales s2 WHERE s2.ss_addr_sk = ca.ca_address_sk) AS address_sales_count
FROM store_sales s
JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
JOIN customer_address ca ON s.ss_addr_sk = ca.ca_address_sk
JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_date >= DATE '2001-01-01'
    AND d.d_date <= DATE '2001-12-31'
    AND cc.cc_market_manager = 'Frederick Weaver'
    AND cc.cc_class = 'large'
    AND ca.ca_state = 'CA'
    AND s.ss_ext_sales_price > 1000.00
    AND s.ss_quantity BETWEEN 1 AND 10
    AND s.ss_net_paid_inc_tax < 5000.00
GROUP BY
    d.d_year,
    cc.cc_market_manager,
    cc.cc_class,
    ca.ca_state,
    ca.ca_address_sk
HAVING
    SUM(s.ss_ext_sales_price) > 50000
ORDER BY
    total_sales DESC,
    year ASC
