WITH sales_agg AS (
    SELECT
        cs.cs_warehouse_sk,
        COUNT(*) AS cnt_sales,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit
    FROM catalog_sales cs
    LEFT OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        cs.cs_list_price > 50
        AND cs.cs_quantity >= 1
        AND cs.cs_sold_time_sk IN (57746, 59689)
        AND w.w_country = 'United States'
        AND w.w_warehouse_id LIKE 'AAAAAAA%'
    GROUP BY cs.cs_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    sales_agg.cnt_sales,
    sales_agg.total_sales,
    sales_agg.avg_profit,
    sales_agg.total_sales / NULLIF(sales_agg.cnt_sales, 0) AS avg_sales_per_txn,
    ROW_NUMBER() OVER (ORDER BY sales_agg.total_sales DESC) AS sales_rank
FROM sales_agg
JOIN warehouse w
    ON sales_agg.cs_warehouse_sk = w.w_warehouse_sk
WHERE
    sales_agg.total_sales > (
        SELECT AVG(total_sales) FROM sales_agg
    )
    AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_warehouse_sk = w.w_warehouse_sk
          AND cs2.cs_ext_discount_amt > 10
    )
ORDER BY sales_agg.total_sales DESC
LIMIT 100
