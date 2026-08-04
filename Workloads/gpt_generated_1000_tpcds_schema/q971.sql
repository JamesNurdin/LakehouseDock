WITH sales_sampled AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
),

intersect_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
    INTERSECT
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_quantity > 0
),

except_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_quantity > 5
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_quantity > 0
)
SELECT
    cp.cp_department,
    r.r_reason_desc,
    SUM(s.cs_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt,
    AVG(cr.cr_return_amount) AS avg_return_amount,
    SUM(CASE WHEN cr.cr_return_amount > 1000 THEN 1 ELSE 0 END) AS high_return_cnt
FROM sales_sampled s
JOIN catalog_page cp
    ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
    ON s.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = s.cs_order_number
   AND cr.cr_item_sk = s.cs_item_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_reason_sk = r.r_reason_sk
WHERE
    cp.cp_type = 'monthly'
    AND r.r_reason_desc LIKE '%price%'
    AND c.c_birth_month = 7
    AND s.cs_order_number IN (SELECT cs_order_number FROM intersect_orders)
    AND s.cs_order_number NOT IN (SELECT cs_order_number FROM except_orders)
    AND NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = s.cs_order_number
    )
GROUP BY GROUPING SETS ((cp.cp_department, r.r_reason_desc), ())
ORDER BY total_net_paid DESC
LIMIT 100
