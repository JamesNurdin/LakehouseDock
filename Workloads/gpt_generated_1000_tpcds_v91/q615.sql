WITH sales_agg1_src AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cs.cs_item_sk,
        CASE WHEN inv.inv_quantity_on_hand > 0 THEN 'InStock' ELSE 'OutOfStock' END AS stock_status,
        cs.cs_ext_sales_price,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT inv_quantity_on_hand, inv_warehouse_sk
        FROM inventory
        WHERE inv_date_sk = d.d_date_sk
          AND inv_warehouse_sk IN (1, 7, 10)
        ORDER BY inv_quantity_on_hand DESC
        LIMIT 1
    ) inv
    WHERE d.d_year = 1998
      AND cs.cs_quantity > 5
      AND inv.inv_quantity_on_hand IS NOT NULL
),
sales_agg1 AS (
    SELECT
        d_year,
        d_month_seq,
        cs_item_sk,
        stock_status,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS order_cnt
    FROM sales_agg1_src
    GROUP BY GROUPING SETS (
        (d_year, d_month_seq, cs_item_sk, stock_status),
        (d_year, d_month_seq, stock_status),
        (d_year, stock_status),
        (stock_status)
    )
),

sales_agg2_src AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cs.cs_item_sk,
        CASE WHEN inv.inv_quantity_on_hand > 0 THEN 'InStock' ELSE 'OutOfStock' END AS stock_status,
        cs.cs_ext_sales_price,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_ship_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT inv_quantity_on_hand, inv_warehouse_sk
        FROM inventory
        WHERE inv_date_sk = d.d_date_sk
          AND inv_warehouse_sk IN (1, 7, 10)
        ORDER BY inv_quantity_on_hand DESC
        LIMIT 1
    ) inv
    WHERE d.d_year = 1998
      AND cs.cs_quantity > 5
      AND inv.inv_quantity_on_hand IS NOT NULL
),
sales_agg2 AS (
    SELECT
        d_year,
        d_month_seq,
        cs_item_sk,
        stock_status,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_quantity) AS total_quantity,
        COUNT(*) AS order_cnt
    FROM sales_agg2_src
    GROUP BY GROUPING SETS (
        (d_year, d_month_seq, cs_item_sk, stock_status),
        (d_year, d_month_seq, stock_status),
        (d_year, stock_status),
        (stock_status)
    )
),

unioned AS (
    SELECT d_year, d_month_seq, cs_item_sk, stock_status, total_sales, total_quantity, order_cnt
    FROM sales_agg1
    UNION
    SELECT d_year, d_month_seq, cs_item_sk, stock_status, total_sales, total_quantity, order_cnt
    FROM sales_agg2
),

final_ranked AS (
    SELECT
        d_year,
        d_month_seq,
        cs_item_sk,
        stock_status,
        total_sales,
        total_quantity,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY stock_status ORDER BY total_sales DESC) AS rank_within_stock
    FROM unioned
    WHERE total_sales > 0
)
SELECT
    d_year,
    d_month_seq,
    cs_item_sk,
    stock_status,
    total_sales,
    total_quantity,
    order_cnt,
    rank_within_stock
FROM final_ranked
ORDER BY total_sales DESC, rank_within_stock
LIMIT 100
