WITH sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_net_paid,
        ss.ss_ext_tax,
        ss.ss_list_price,
        ss.ss_quantity
    FROM tpcds.store_sales ss
    WHERE ss.ss_list_price > 50
      AND ss.ss_quantity >= 1
)
SELECT
    s.s_store_name,
    ca.ca_city,
    c.c_salutation,
    COUNT(DISTINCT sales.ss_ticket_number) AS num_transactions,
    SUM(sales.ss_net_paid) AS total_sales,
    SUM(COALESCE(r.sr_refunded_cash, 0)) AS total_refunds,
    AVG(sales.ss_ext_tax) AS avg_tax,
    MIN(sales.ss_list_price) AS min_price,
    MAX(sales.ss_list_price) AS max_price
FROM sales
JOIN tpcds.customer c
    ON sales.ss_customer_sk = c.c_customer_sk
JOIN tpcds.customer_address ca
    ON sales.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.store s
    ON sales.ss_store_sk = s.s_store_sk
LEFT JOIN tpcds.store_returns r
    ON sales.ss_ticket_number = r.sr_ticket_number
WHERE c.c_salutation = 'Mrs.'
  AND c.c_last_name = 'Williams'
  AND ca.ca_state = 'CA'
  AND s.s_rec_start_date >= DATE '2001-01-01'
  AND s.s_rec_start_date < DATE '2002-01-01'
  AND NOT EXISTS (
        SELECT 1 FROM tpcds.store_returns r2
        WHERE r2.sr_customer_sk = c.c_customer_sk
          AND r2.sr_return_quantity > 0
    )
GROUP BY s.s_store_name, ca.ca_city, c.c_salutation
ORDER BY total_sales DESC
LIMIT 100
