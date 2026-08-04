WITH sales_data AS (
    SELECT d.d_year AS year,
           ca.ca_county,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ca.ca_county
),
returns_data AS (
    SELECT d.d_year AS year,
           ca.ca_county,
           SUM(wr.wr_return_amt) AS total_returns,
           COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ca.ca_state = 'CA'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, ca.ca_county
),
combined AS (
    SELECT year,
           ca_county,
           total_sales AS amount,
           sales_cnt AS cnt,
           'sale'   AS type
    FROM sales_data
    UNION ALL
    SELECT year,
           ca_county,
           total_returns AS amount,
           return_cnt   AS cnt,
           'return'     AS type
    FROM returns_data
)
SELECT c.year,
       c.ca_county,
       c.type,
       c.amount,
       c.cnt,
       lt.total_year_amount
FROM combined c
CROSS JOIN LATERAL (
    SELECT SUM(amount) AS total_year_amount
    FROM combined c2
    WHERE c2.year = c.year
) AS lt
WHERE c.amount > 0
ORDER BY c.year, c.ca_county, c.type
LIMIT 100
