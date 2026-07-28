WITH sales_agg AS (
    SELECT
        cp.cp_department,
        w.w_warehouse_name,
        d_sold.d_year,
        SUM(cs.cs_net_profit)            AS total_profit,
        SUM(cs.cs_quantity)               AS total_quantity,
        AVG(cs.cs_sales_price)            AS avg_sales_price,
        MAX(i.inv_quantity_on_hand)       AS max_inventory_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i
        ON i.inv_date_sk = d_sold.d_date_sk
       AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_sold.d_year = 2001
      AND cp.cp_catalog_number = 10
      AND t.t_sub_shift = 'morning'
    GROUP BY cp.cp_department, w.w_warehouse_name, d_sold.d_year
    HAVING SUM(cs.cs_quantity) > 100
)
SELECT
    sa.cp_department,
    ROUND(AVG(sa.total_profit), 2)            AS avg_profit_per_warehouse,
    COUNT(*)                                 AS warehouse_count,
    (SELECT COUNT(*) FROM promotion p_sub WHERE p_sub.p_discount_active = 'Y') AS total_active_promotions
FROM sales_agg sa
GROUP BY sa.cp_department
HAVING AVG(sa.total_profit) > 5000
ORDER BY avg_profit_per_warehouse DESC
LIMIT 100
