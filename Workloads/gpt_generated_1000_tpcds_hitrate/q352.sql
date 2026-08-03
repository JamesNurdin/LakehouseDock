WITH sales_data AS (
    SELECT
        ca.ca_country AS country,
        cs.cs_net_paid AS amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_start_date_sk = cs.cs_sold_date_sk
            AND p.p_end_date_sk >= cs.cs_sold_date_sk
      )
),
returns_data AS (
    SELECT
        ca.ca_country AS country,
        wr.wr_refunded_cash AS amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_start_date_sk = wr.wr_returned_date_sk
            AND p.p_end_date_sk >= wr.wr_returned_date_sk
      )
)
SELECT
    u.country,
    SUM(u.amount) AS total_amount
FROM (
    SELECT DISTINCT country, amount FROM sales_data
    UNION ALL
    SELECT DISTINCT country, amount FROM returns_data
) u
GROUP BY u.country
ORDER BY total_amount DESC
LIMIT 10
