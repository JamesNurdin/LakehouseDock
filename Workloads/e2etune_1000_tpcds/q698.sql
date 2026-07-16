WITH agg AS (
    SELECT
        sm.sm_type AS ship_mode,
        w.w_state AS warehouse_state,
        i.i_category AS product_category,
        i.i_brand AS product_brand,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(cs.cs_net_profit) / NULLIF(SUM(cs.cs_net_paid_inc_tax), 0) AS profit_margin
    FROM catalog_sales cs
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ext_discount_amt > 500
      AND cs.cs_sales_price BETWEEN 20 AND 150
      AND sm.sm_type IN ('AIR', 'RAIL', 'TRUCK')
    GROUP BY sm.sm_type, w.w_state, i.i_category, i.i_brand
    HAVING SUM(cs.cs_net_paid_inc_tax) > 10000
)
SELECT
    ship_mode,
    warehouse_state,
    product_category,
    product_brand,
    distinct_orders,
    total_quantity,
    total_sales,
    total_discount,
    avg_sales_price,
    profit_margin,
    RANK() OVER (PARTITION BY warehouse_state ORDER BY total_sales DESC) AS sales_rank_state
FROM agg
ORDER BY total_sales DESC
LIMIT 100
