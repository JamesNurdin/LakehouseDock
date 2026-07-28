WITH agg_sales_returns AS (
    SELECT
        i.i_category,
        i.i_brand,
        i.i_manager_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_orders,
        COUNT(DISTINCT wr.wr_order_number) AS return_orders
    FROM tpcds.inventory inv
    JOIN tpcds.item i ON inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.reason r ON r.r_reason_sk = wr.wr_reason_sk
    WHERE ss.ss_list_price > 50
      AND ss.ss_quantity >= 2
      AND inv.inv_quantity_on_hand > 10
      AND i.i_units = 'Lb'
      AND wr.wr_reversed_charge < 200
    GROUP BY GROUPING SETS (
        (i.i_category, i.i_brand, i.i_manager_id),
        (i.i_category, i.i_brand),
        (i.i_category),
        ()
    )
)
SELECT
    i_category,
    AVG(total_sales) AS avg_total_sales,
    SUM(total_returns) AS sum_total_returns,
    ROW_NUMBER() OVER (ORDER BY AVG(total_sales) DESC) AS category_rank
FROM agg_sales_returns
WHERE total_sales IS NOT NULL
GROUP BY i_category
HAVING AVG(total_sales) > 1000
ORDER BY avg_total_sales DESC
LIMIT 100
