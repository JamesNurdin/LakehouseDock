WITH filtered_sales AS (
    SELECT
        ss_item_sk,
        ss_ext_sales_price,
        ss_net_paid,
        ss_net_profit,
        ss_wholesale_cost,
        ss_ext_tax,
        ss_quantity
    FROM store_sales
    WHERE ss_wholesale_cost > 10
      AND ss_ext_tax < 30
      AND ss_quantity >= 2
),
aggregated_sales AS (
    SELECT
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_net_profit) AS total_profit
    FROM filtered_sales
    GROUP BY ss_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_units,
    COALESCE(a.total_sales, 0) AS total_sales,
    COALESCE(a.total_net_paid, 0) AS total_net_paid,
    COALESCE(a.total_profit, 0) AS total_profit,
    CASE WHEN COALESCE(a.total_profit, 0) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY i.i_category ORDER BY COALESCE(a.total_net_paid, 0) DESC) AS category_rank
FROM aggregated_sales a
RIGHT OUTER JOIN item i
    ON a.ss_item_sk = i.i_item_sk
WHERE i.i_rec_end_date > DATE '1999-12-31'
  AND i.i_units IN ('Box', 'Case')
  AND i.i_class_id IN (2, 3)
ORDER BY i.i_category, category_rank
OFFSET 0 LIMIT 100
