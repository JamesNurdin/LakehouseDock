WITH sales_with_category AS (
    SELECT
        cs.cs_sold_date_sk,
        cc.cc_call_center_id,
        w.w_warehouse_id,
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_profit,
        CASE
            WHEN cs.cs_net_profit > 1000 THEN 'High'
            WHEN cs.cs_net_profit BETWEEN 0 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON cs.cs_sold_date_sk = inv.inv_date_sk
        AND cs.cs_item_sk = inv.inv_item_sk
        AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
),
monthly_category_summary AS (
    SELECT
        cs_sold_date_sk,
        cc_call_center_id,
        profit_category,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_net_profit) AS total_profit,
        AVG(inv_quantity_on_hand) AS avg_inventory_qty
    FROM sales_with_category
    GROUP BY cs_sold_date_sk, cc_call_center_id, profit_category
),
monthly_totals AS (
    SELECT
        cs_sold_date_sk,
        cc_call_center_id,
        SUM(total_profit) AS month_total_profit,
        SUM(orders_cnt) AS month_total_orders,
        AVG(avg_inventory_qty) AS month_avg_inventory_qty
    FROM monthly_category_summary
    GROUP BY cs_sold_date_sk, cc_call_center_id
)
SELECT
    mcs.cs_sold_date_sk,
    mcs.cc_call_center_id,
    mcs.profit_category,
    mcs.orders_cnt,
    mcs.total_profit,
    ROUND(100.0 * mcs.total_profit / mt.month_total_profit, 2) AS profit_pct_of_month,
    mt.month_total_orders,
    mt.month_avg_inventory_qty,
    LAG(mt.month_total_profit) OVER (PARTITION BY mcs.cc_call_center_id ORDER BY mcs.cs_sold_date_sk) AS prev_month_profit,
    CASE
        WHEN LAG(mt.month_total_profit) OVER (PARTITION BY mcs.cc_call_center_id ORDER BY mcs.cs_sold_date_sk) IS NULL THEN NULL
        WHEN LAG(mt.month_total_profit) OVER (PARTITION BY mcs.cc_call_center_id ORDER BY mcs.cs_sold_date_sk) = 0 THEN NULL
        ELSE ROUND(100.0 * (mt.month_total_profit - LAG(mt.month_total_profit) OVER (PARTITION BY mcs.cc_call_center_id ORDER BY mcs.cs_sold_date_sk)) / LAG(mt.month_total_profit) OVER (PARTITION BY mcs.cc_call_center_id ORDER BY mcs.cs_sold_date_sk), 2)
    END AS mom_profit_growth_pct
FROM monthly_category_summary mcs
JOIN monthly_totals mt
    ON mcs.cs_sold_date_sk = mt.cs_sold_date_sk
   AND mcs.cc_call_center_id = mt.cc_call_center_id
ORDER BY mcs.cc_call_center_id, mcs.cs_sold_date_sk, mcs.profit_category
LIMIT 200
