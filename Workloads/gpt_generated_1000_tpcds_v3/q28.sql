WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        w.w_zip,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_net_profit) AS avg_net_profit,
        COUNT(*) AS sales_count
    FROM
        catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE
        i.i_manufact IN ('ableanti', 'antiablecally')
        AND i.i_units = 'Dozen'
        AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450840
        AND w.w_warehouse_name LIKE '%Proceedings%'
        AND w.w_zip = '33604'
        AND cs.cs_quantity > 0
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        w.w_zip
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.w_warehouse_name,
    sa.w_zip,
    sa.total_quantity,
    sa.total_net_paid,
    sa.total_net_profit,
    sa.sales_count,
    CASE
        WHEN sa.total_quantity > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_item_id = sa.i_item_id
    ) AS overall_item_avg_net_profit,
    RANK() OVER (PARTITION BY sa.w_warehouse_name ORDER BY sa.total_net_profit DESC) AS profit_rank,
    SUM(sa.total_quantity) OVER (
        PARTITION BY sa.w_warehouse_name
        ORDER BY sa.total_net_profit DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_quantity
FROM sales_agg sa
WHERE sa.total_net_profit > 0
ORDER BY sa.w_warehouse_name, profit_rank
LIMIT 100
