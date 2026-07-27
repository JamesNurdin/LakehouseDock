WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_customer_sk = c.c_customer_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_fy_year = 1915
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND cs.cs_ext_sales_price > 1000
      AND ss.ss_ext_sales_price > 5000
      AND wr.wr_return_amt > 200
      AND r.r_reason_desc = 'Damaged Item'
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
)
SELECT
    b.c_customer_sk,
    b.c_first_name,
    b.c_last_name,
    b.d_year,
    b.catalog_net_paid,
    b.store_net_paid,
    b.total_return_amt,
    (b.catalog_net_paid + b.store_net_paid - b.total_return_amt) AS net_contribution,
    ROUND((b.catalog_net_paid + b.store_net_paid - b.total_return_amt) / NULLIF(b.catalog_orders + b.store_tickets, 0), 2) AS avg_net_per_transaction
FROM base b
WHERE (b.catalog_net_paid + b.store_net_paid - b.total_return_amt) > 5000
ORDER BY net_contribution DESC
LIMIT 100
