WITH joined_agg AS (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        cp.cp_department AS department,
        d_sold.d_date AS sales_date,
        cs.cs_order_number AS order_number,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand
    FROM catalog_sales cs
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN inventory i
      ON i.inv_warehouse_sk = w.w_warehouse_sk
     AND i.inv_date_sk = d_sold.d_date_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d_sold.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND cp.cp_department = 'Electronics'
      AND p.p_purpose = 'Unknown'
      AND w.w_state = 'CA'
      AND cs.cs_quantity > 5
      AND i.inv_quantity_on_hand >= 0
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        cp.cp_department,
        d_sold.d_date,
        cs.cs_order_number
)
SELECT
    store_id,
    store_name,
    department,
    sales_date,
    total_net_profit,
    total_quantity,
    CASE WHEN total_net_profit > 100000 THEN 'High' ELSE 'Medium' END AS profit_category,
    RANK() OVER (PARTITION BY department ORDER BY total_net_profit DESC) AS dept_store_profit_rank,
    SUM(total_inventory_on_hand) OVER (PARTITION BY store_id ORDER BY sales_date ROWS BETWEEN 30 PRECEDING AND CURRENT ROW) AS moving_inventory_30d,
    (SELECT MAX(p3.p_cost) FROM promotion p3 WHERE p3.p_purpose = 'Unknown') AS max_unknown_promo_cost
FROM joined_agg ja
WHERE NOT EXISTS (
    SELECT 1 FROM web_returns wr2
    WHERE wr2.wr_order_number = ja.order_number
)
ORDER BY total_net_profit DESC
LIMIT 100
