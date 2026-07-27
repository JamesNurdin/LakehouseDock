/*
Goal: Compare yearly sales performance with yearly web return performance by state for the year 2001, include a profit flag, overall average discount, and filter returns to states that had a web site open in 2001. The results from sales and returns are combined with UNION ALL and ordered.
*/
WITH sales_data AS (
    SELECT
        d.d_year AS d_year,
        ca.ca_state AS ca_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, ca.ca_state
),
returns_data AS (
    SELECT
        d.d_year AS d_year,
        ca.ca_state AS ca_state,
        SUM(wr.wr_return_amt) AS total_sales,
        SUM(wr.wr_net_loss) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, ca.ca_state
)
SELECT
    sd.d_year,
    sd.ca_state,
    'sales' AS record_type,
    sd.total_sales,
    sd.total_profit,
    sd.sales_cnt,
    CASE WHEN sd.total_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
    (
        SELECT AVG(ss2.ss_ext_discount_amt)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS overall_avg_discount
FROM sales_data sd
UNION ALL
SELECT
    rd.d_year,
    rd.ca_state,
    'returns' AS record_type,
    rd.total_sales,
    rd.total_profit,
    rd.sales_cnt,
    CASE WHEN rd.total_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag,
    (
        SELECT AVG(ss2.ss_ext_discount_amt)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS overall_avg_discount
FROM returns_data rd
WHERE EXISTS (
    SELECT 1
    FROM web_site ws
    JOIN date_dim d4 ON ws.web_open_date_sk = d4.d_date_sk
    WHERE d4.d_year = 2001
      AND ws.web_state = rd.ca_state
)
ORDER BY d_year DESC, ca_state, record_type
LIMIT 100
