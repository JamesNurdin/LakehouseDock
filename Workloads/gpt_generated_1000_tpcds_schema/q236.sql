WITH purchase_customers AS (
    SELECT cs_bill_customer_sk AS customer_sk,
           SUM(cs_net_paid) AS total_sales
    FROM catalog_sales
    JOIN item ON catalog_sales.cs_item_sk = item.i_item_sk
    JOIN time_dim ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
    WHERE regexp_like(item.i_product_name, '^.*[A-Z]{2,}.*$')
      AND time_dim.t_hour BETWEEN 9 AND 17
    GROUP BY cs_bill_customer_sk
    HAVING SUM(cs_net_paid) > 1000
),
return_customers AS (
    SELECT cr_refunded_customer_sk AS customer_sk,
           SUM(cr_return_amount) AS total_returns
    FROM catalog_returns
    JOIN reason ON catalog_returns.cr_reason_sk = reason.r_reason_sk
    WHERE reason.r_reason_desc LIKE '%defect%'
      AND regexp_extract(reason.r_reason_desc, '(\\d+)', 1) IS NOT NULL
    GROUP BY cr_refunded_customer_sk
    HAVING SUM(cr_return_amount) > 200
),
common_customers AS (
    SELECT customer_sk FROM purchase_customers
    INTERSECT
    SELECT customer_sk FROM return_customers
)
SELECT c.c_customer_id,
       pc.total_sales,
       rc.total_returns,
       CASE WHEN pc.total_sales > rc.total_returns THEN 'Profit' ELSE 'Loss' END AS status
FROM common_customers cc
JOIN purchase_customers pc ON cc.customer_sk = pc.customer_sk
JOIN return_customers rc ON cc.customer_sk = rc.customer_sk
JOIN customer c ON cc.customer_sk = c.c_customer_sk
ORDER BY status DESC, total_sales DESC
LIMIT 100
