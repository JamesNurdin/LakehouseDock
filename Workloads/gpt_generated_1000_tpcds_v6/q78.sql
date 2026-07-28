/*
  Goal:  Analyze revenue performance by warehouse and call‑center, compare sales vs. returns, rank warehouses by sales, and flag profitability. The query joins all seven TPC‑DS tables, applies multiple filters, uses a CTE, a scalar EXISTS subquery, a UNION ALL set operation, CASE logic, GROUPING SETS aggregation, and window functions, then orders and limits the result.
*/
WITH sales_detail AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        c.c_customer_id,
        c.c_birth_year,
        ca.ca_city,
        cc.cc_name,
        cc.cc_state,
        cp.cp_department,
        w.w_warehouse_name,
        w.w_city
    FROM catalog_sales cs
    JOIN customer c               ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w              ON cs.cs_warehouse_sk = w.w_warehouse_sk
),
union_agg AS (
    SELECT
        sd.w_warehouse_name AS warehouse,
        'sales' AS metric,
        SUM(sd.cs_ext_sales_price) AS total_amount
    FROM sales_detail sd
    WHERE sd.c_birth_year < 1950
    GROUP BY sd.w_warehouse_name
    UNION ALL
    SELECT
        sd.w_warehouse_name,
        'high_returns',
        SUM(sr.sr_return_amt)
    FROM sales_detail sd
    JOIN store_returns sr ON sr.sr_customer_sk = sd.cs_bill_customer_sk
    WHERE sr.sr_return_amt > 300
    GROUP BY sd.w_warehouse_name
),
final_agg AS (
    SELECT
        sd.w_warehouse_name,
        cc.cc_name,
        SUM(sd.cs_ext_sales_price) AS total_sales,
        SUM(sr.sr_return_amt)      AS total_returns,
        CASE
            WHEN SUM(sd.cs_ext_sales_price) - SUM(sr.sr_return_amt) > 50000 THEN 'PROFITABLE'
            ELSE 'LESS_PROFITABLE'
        END AS profit_flag
    FROM sales_detail sd
    JOIN store_returns sr ON sr.sr_customer_sk = sd.cs_bill_customer_sk
    JOIN call_center cc   ON sd.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_state = 'CA'
      AND sd.c_birth_year BETWEEN 1930 AND 1990
      AND w_city = 'Lincoln'
      AND sr.sr_return_amt > 100
      AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_department = 'Electronics'
              AND cp2.cp_catalog_page_sk = sd.cs_catalog_page_sk
        )
    GROUP BY GROUPING SETS (
        (sd.w_warehouse_name, cc.cc_name),
        (sd.w_warehouse_name),
        (cc.cc_name)
    )
)
SELECT
    fa.w_warehouse_name,
    fa.cc_name,
    fa.total_sales,
    fa.total_returns,
    fa.profit_flag,
    ua.metric,
    ua.total_amount,
    ROW_NUMBER() OVER (PARTITION BY fa.w_warehouse_name ORDER BY fa.total_sales DESC) AS sales_rank,
    SUM(fa.total_returns) OVER (
        PARTITION BY fa.w_warehouse_name
        ORDER BY fa.total_sales
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_returns
FROM final_agg fa
LEFT JOIN union_agg ua ON ua.warehouse = fa.w_warehouse_name
ORDER BY fa.total_sales DESC
LIMIT 100
