WITH sales_warehouse AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_ext_list_price,
        cs.cs_ext_ship_cost,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_warehouse_sk,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_state,
        w.w_gmt_offset
    FROM catalog_sales cs
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_ext_list_price > 5000
      AND cs.cs_ext_ship_cost < 1000
      AND w.w_state = 'TX'
      AND w.w_gmt_offset BETWEEN -6.00 AND -5.00
      AND cs.cs_quantity >= 2
),
agg AS (
    SELECT
        sw.w_warehouse_name,
        sw.cs_sold_date_sk,
        SUM(sw.cs_ext_sales_price) AS total_sales,
        AVG(cr.cr_return_amount) AS avg_return_amount,
        COUNT(DISTINCT sw.cs_order_number) AS unique_orders
    FROM sales_warehouse sw
    JOIN catalog_returns cr
      ON cr.cr_order_number = sw.cs_order_number
     AND cr.cr_item_sk = sw.cs_item_sk
    WHERE cr.cr_return_quantity > 0
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = sw.cs_order_number
              AND cr2.cr_refunded_cash > 0
          )
    GROUP BY GROUPING SETS (
        (sw.w_warehouse_name, sw.cs_sold_date_sk),
        (sw.w_warehouse_name),
        (sw.cs_sold_date_sk)
    )
)
SELECT
    a.w_warehouse_name,
    a.cs_sold_date_sk,
    a.total_sales,
    a.avg_return_amount,
    a.unique_orders,
    ROW_NUMBER() OVER (PARTITION BY a.w_warehouse_name ORDER BY a.total_sales DESC) AS sales_rank
FROM agg a
ORDER BY a.total_sales DESC
LIMIT 100
