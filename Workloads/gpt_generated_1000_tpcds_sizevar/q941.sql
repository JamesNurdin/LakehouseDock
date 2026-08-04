WITH
  -- total sales per billed customer for the year 2020
  sales_customers AS (
    SELECT
      cs.cs_bill_customer_sk AS cust_sk,
      SUM(cs.cs_ext_sales_price) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY cs.cs_bill_customer_sk
  ),

  -- total returns per returning customer for the year 2020
  returns_customers AS (
    SELECT
      wr.wr_returning_customer_sk AS cust_sk,
      SUM(wr.wr_return_amt) AS total_returns
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY wr.wr_returning_customer_sk
  ),

  -- customers who have sales but never appear in returns (EXCEPT)
  sales_without_returns AS (
    SELECT cust_sk
    FROM sales_customers
    EXCEPT
    SELECT cust_sk
    FROM returns_customers
  ),

  -- Catalog page enriched with its start date (FULL OUTER JOIN as required)
  page_date AS (
    SELECT
      cp.cp_catalog_page_sk,
      cp.cp_department,
      d.d_year AS page_year
    FROM catalog_page cp
    FULL OUTER JOIN date_dim d
      ON cp.cp_start_date_sk = d.d_date_sk
  ),

  -- First branch of the UNION: sales rows
  sales_union AS (
    SELECT
      c.c_customer_id,
      d.d_year,
      cs.cs_ext_sales_price               AS total_amount,
      CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
      EXISTS (
        SELECT 1
        FROM warehouse w
        WHERE w.w_warehouse_sk = cs.cs_warehouse_sk
          AND w.w_city = 'Seattle'
      )                                 AS sold_from_seattle,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_ext_sales_price DESC) AS rn
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN sales_without_returns swo ON cs.cs_bill_customer_sk = swo.cust_sk
    JOIN page_date pd ON cs.cs_catalog_page_sk = pd.cp_catalog_page_sk
  ),

  -- Second branch of the UNION: return rows (negative amount to contrast)
  returns_union AS (
    SELECT
      c.c_customer_id,
      d.d_year,
      -wr.wr_return_amt                     AS total_amount,
      CASE WHEN wr.wr_return_amt > 500 THEN 'Large Return' ELSE 'Small Return' END AS sales_category,
      FALSE                                 AS sold_from_seattle,
      ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY wr.wr_return_amt DESC) AS rn
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
  ),

  -- Combine the two branches with UNION (distinct)
  final_union AS (
    SELECT c_customer_id, d_year, total_amount, sales_category, sold_from_seattle, rn
    FROM sales_union
    UNION
    SELECT c_customer_id, d_year, total_amount, sales_category, sold_from_seattle, rn
    FROM returns_union
  )

SELECT
  c_customer_id,
  d_year,
  total_amount,
  sales_category,
  sold_from_seattle,
  rn
FROM final_union
ORDER BY c_customer_id, rn
