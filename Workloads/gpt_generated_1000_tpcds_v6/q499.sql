WITH joined_data AS (
    SELECT
        cp.cp_department AS department,
        cp.cp_catalog_page_number AS catalog_page_number,
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_fee,
        cr.cr_returned_date_sk
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_bill_customer_sk = cr.cr_returning_customer_sk
        AND cs.cs_catalog_page_sk = cr.cr_catalog_page_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2451000 AND 2452000
      AND cs.cs_quantity > 1
      AND cs.cs_wholesale_cost > 0
      AND cs.cs_list_price > cs.cs_wholesale_cost
      AND cp.cp_type = 'Catalog'
      AND c.c_preferred_cust_flag = 'Y'
      AND (cr.cr_returned_date_sk IS NULL OR cr.cr_returned_date_sk BETWEEN 2451000 AND 2452000)
      AND (cr.cr_fee IS NULL OR cr.cr_fee > 5)
),
agg AS (
    SELECT
        department,
        catalog_page_number,
        cust_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS order_cnt,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        SUM(CASE WHEN cr_return_quantity IS NOT NULL THEN cr_return_quantity ELSE 0 END) AS total_return_qty,
        CASE WHEN SUM(cs_ext_sales_price) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM joined_data
    GROUP BY department, catalog_page_number, cust_sk
)
SELECT
    a.department,
    a.sales_category,
    COUNT(*) AS num_customers,
    SUM(a.total_sales) AS dept_total_sales,
    AVG(a.total_profit) AS avg_profit,
    SUM(a.total_return_amount) AS dept_total_returns,
    (
        SELECT MAX(cp_end_date_sk)
        FROM catalog_page cp
        WHERE cp.cp_department = a.department
    ) AS latest_page_end_sk,
    CASE
        WHEN SUM(a.total_return_amount) > 0.1 * SUM(a.total_sales) THEN 'HIGH_RETURN'
        ELSE 'LOW_RETURN'
    END AS return_risk
FROM agg a
WHERE a.total_sales > 0
  AND a.total_profit <> 0
  AND a.total_return_qty < 100
  AND a.sales_category = 'HIGH'
  AND a.cust_sk IN (
        SELECT c_customer_sk
        FROM customer
        WHERE c_birth_year BETWEEN 1970 AND 1990
    )
GROUP BY a.department, a.sales_category
HAVING AVG(a.total_profit) > 5000
ORDER BY dept_total_sales DESC
LIMIT 100
