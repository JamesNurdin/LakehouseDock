/*
Goal: Analyze sales performance by brand and customer demographic, focusing on high‑value items sold at a specific store price point and filtered by color, size, manager, and customer attributes. The query joins the fact table store_sales with item and customer_demographics, applies multiple realistic predicates, uses a scalar subquery, counts distinct customers, and orders by total sales.
*/
WITH brand_avg_price AS (
    SELECT i_brand,
           AVG(i_current_price) AS avg_price
    FROM item
    WHERE i_manager_id IN (4, 23, 40)
    GROUP BY i_brand
)
SELECT
    i.i_brand,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.ss_ext_sales_price)               AS total_sales,
    AVG(ss.ss_net_profit)                    AS avg_profit,
    COUNT(DISTINCT ss.ss_customer_sk)        AS unique_customers,
    MAX(ss.ss_ext_sales_price)               AS max_sale,
    MIN(ss.ss_ext_sales_price)               AS min_sale
FROM store_sales ss
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN brand_avg_price bap
    ON i.i_brand = bap.i_brand
WHERE
    i.i_color IN ('red', 'purple', 'turquoise')
    AND i.i_size = 'large'
    AND i.i_manager_id = 23
    AND cd.cd_gender = 'M'
    AND cd.cd_marital_status = 'M'
    AND cd.cd_purchase_estimate >= 2000
    AND ss.ss_wholesale_cost > 10.00
    AND ss.ss_ext_sales_price > (
        SELECT AVG(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = ss.ss_item_sk
    )
GROUP BY
    i.i_brand,
    cd.cd_gender,
    cd.cd_marital_status
ORDER BY total_sales DESC
LIMIT 100
