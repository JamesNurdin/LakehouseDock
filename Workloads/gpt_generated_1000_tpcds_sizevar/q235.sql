WITH sales_by_year_company AS (
    SELECT
        d.d_year,
        c.cc_company,
        c.cc_state,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS cnt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN call_center c
        ON c.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1998 AND 2002
      AND c.cc_gmt_offset = -5.00
      AND c.cc_company IN (1, 2, 3)
      AND c.cc_state IN ('CA', 'NY')
      AND ss.ss_ext_wholesale_cost > 1000
      AND ss.ss_ext_discount_amt >= 0
      AND ss.ss_quantity >= 1
    GROUP BY d.d_year, c.cc_company, c.cc_state
)
SELECT
    d_year,
    cc_company,
    cc_state,
    total_sales,
    total_profit,
    cnt,
    total_profit / NULLIF(cnt, 0) AS avg_profit_per_sale
FROM sales_by_year_company
WHERE total_sales > 50000
  AND total_profit > 10000
  AND cnt >= 5
  AND cc_state = 'CA'
  AND cc_company = 2
  AND EXISTS (
        SELECT 1
        FROM store_sales ss4
        JOIN date_dim d4 ON ss4.ss_sold_date_sk = d4.d_date_sk
        WHERE d4.d_year = sales_by_year_company.d_year
          AND ss4.ss_ext_discount_amt > 0
    )
UNION
SELECT
    d_year,
    cc_company,
    cc_state,
    total_sales,
    total_profit,
    cnt,
    total_profit / NULLIF(cnt, 0) AS avg_profit_per_sale
FROM sales_by_year_company
WHERE total_sales > 60000
  AND total_profit > 15000
  AND cnt >= 10
  AND cc_state = 'NY'
  AND cc_company = 1
  AND EXISTS (
        SELECT 1
        FROM store_sales ss5
        JOIN date_dim d5 ON ss5.ss_sold_date_sk = d5.d_date_sk
        WHERE d5.d_year = sales_by_year_company.d_year
          AND ss5.ss_ext_discount_amt > 0
    )
ORDER BY total_sales DESC
LIMIT 100
