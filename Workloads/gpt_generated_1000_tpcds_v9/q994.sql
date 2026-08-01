WITH returned_orders AS (
    SELECT cr_order_number
    FROM catalog_returns
    WHERE cr_return_tax > 12.00
      AND cr_return_ship_cost BETWEEN 70 AND 180
      AND cr_refunded_cash < 400.00
),
sales_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_wholesale_cost <= 30.00
      AND cs_list_price >= 80.00
),
order_diff AS (
    SELECT cr_order_number
    FROM returned_orders
    EXCEPT
    SELECT cs_order_number
    FROM sales_orders
)
SELECT
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cs.cs_ship_mode_sk,
    COUNT(*) AS return_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    MIN(cs.cs_net_paid_inc_ship) AS min_net_paid_inc_ship,
    MAX(cr.cr_return_tax) AS max_return_tax,
    SUM(CASE WHEN cr.cr_return_amount > cs.cs_sales_price THEN cr.cr_return_amount ELSE 0 END) AS sum_return_gt_sales,
    (SELECT AVG(cs2.cs_sales_price)
     FROM catalog_sales cs2
     WHERE cs2.cs_item_sk = cr.cr_item_sk) AS avg_sales_price_for_item
FROM
    catalog_returns cr
CROSS JOIN LATERAL (
    SELECT *
    FROM catalog_sales cs_inner
    WHERE cs_inner.cs_item_sk = cr.cr_item_sk
      AND cs_inner.cs_order_number = cr.cr_order_number
      AND cs_inner.cs_wholesale_cost <= 30.00
      AND cs_inner.cs_list_price >= 80.00
) AS cs
WHERE
    cr.cr_return_tax > 12.00
    AND cr.cr_return_ship_cost BETWEEN 70 AND 180
    AND cr.cr_refunded_cash < 400.00
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs_exists
        WHERE cs_exists.cs_order_number = cr.cr_order_number
          AND cs_exists.cs_item_sk = cr.cr_item_sk
          AND cs_exists.cs_sales_price > 100.00
    )
    AND cr.cr_order_number IN (SELECT cr_order_number FROM order_diff)
GROUP BY
    cr.cr_returned_date_sk,
    cr.cr_item_sk,
    cs.cs_ship_mode_sk
HAVING
    COUNT(*) > 1
ORDER BY
    total_return_amount DESC
LIMIT 100
