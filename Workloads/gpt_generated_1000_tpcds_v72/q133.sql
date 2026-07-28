WITH sales_store_agg AS (
    SELECT
        s.s_store_id,
        cp.cp_catalog_page_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders
    FROM catalog_sales cs
    JOIN date_dim d            ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t            ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c           ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN store_returns sr     ON sr.sr_returned_date_sk = d.d_date_sk
                               AND sr.sr_item_sk = cs.cs_item_sk
                               AND sr.sr_customer_sk = c.c_customer_sk
    JOIN store s               ON sr.sr_store_sk = s.s_store_sk
    JOIN inventory inv        ON inv.inv_date_sk = cs.cs_sold_date_sk
                               AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_warehouse_id IN ('AAAAAAAACBAAAAAA','AAAAAAAADAAAAAAA')
      AND s.s_state = 'CA'
      AND cp.cp_type = 'catalog'
      AND t.t_meal_time = 'lunch'
      AND cs.cs_quantity > 5
      AND inv.inv_quantity_on_hand > 0
      AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_customer_sk = c.c_customer_sk
              AND wp.wp_type = 'home'
              AND wp.wp_creation_date_sk = d.d_date_sk
      )
    GROUP BY s.s_store_id, cp.cp_catalog_page_id
)
SELECT
    s_store_id,
    cp_catalog_page_id,
    total_sales,
    total_returns,
    avg_inventory,
    num_orders,
    (total_sales - total_returns) / NULLIF(total_sales, 0) AS net_margin
FROM sales_store_agg
WHERE (total_sales - total_returns) > 1000
  AND (total_sales - total_returns) / NULLIF(total_sales, 0) > 0.1
ORDER BY total_sales DESC
LIMIT 100
