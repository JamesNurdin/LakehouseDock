-- Goal: Compare total net paid and profit for California customers from store sales and catalog sales, include each customer's web return count, and list the top results.
WITH store_customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(ss.ss_net_paid)               AS total_net_paid,
        SUM(ss.ss_net_profit)             AS total_profit,
        'store'                            AS sales_channel,
        (SELECT COUNT(*)
         FROM web_returns wr
         WHERE wr.wr_refunded_customer_sk = c.c_customer_sk) AS return_count
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.ca_state,
    cs.total_net_paid,
    cs.total_profit,
    cs.sales_channel,
    cs.return_count
FROM (
    SELECT * FROM store_customer_summary
    UNION ALL
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        SUM(cs.cs_net_paid)               AS total_net_paid,
        SUM(cs.cs_net_profit)             AS total_profit,
        'catalog'                         AS sales_channel,
        (SELECT COUNT(*)
         FROM web_returns wr
         WHERE wr.wr_refunded_customer_sk = c.c_customer_sk) AS return_count
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_state
) AS cs
ORDER BY cs.total_net_paid DESC
LIMIT 100
