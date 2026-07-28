WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_warehouse_sk,
        cp.cp_department,
        sm.sm_type,
        w.w_warehouse_name,
        w.w_state,
        ss.ss_store_sk,
        s.s_store_name,
        d_sold.d_year,
        cs.cs_net_paid,
        cs.cs_net_profit,
        CASE WHEN cs.cs_ext_discount_amt > 100 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND sm.sm_type IN ('EXPRESS', 'OVERNIGHT')
      AND w.w_state = 'CA'
      AND cp.cp_department = 'Electronics'
)
SELECT
    sa.cp_department,
    sa.s_store_name,
    sa.w_warehouse_name,
    sa.d_year,
    SUM(sa.cs_net_paid) AS total_net_paid,
    SUM(sa.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT sa.cs_order_number) AS orders_cnt,
    RANK() OVER (PARTITION BY sa.d_year ORDER BY SUM(sa.cs_net_paid) DESC) AS revenue_rank,
    (SELECT MAX(w2.w_warehouse_sq_ft) FROM warehouse w2 WHERE w2.w_state = 'CA') AS max_ca_warehouse_sq_ft
FROM sales_agg sa
GROUP BY
    sa.cp_department,
    sa.s_store_name,
    sa.w_warehouse_name,
    sa.d_year
HAVING SUM(sa.cs_net_paid) > 100000
ORDER BY revenue_rank, total_net_paid DESC
LIMIT 100
