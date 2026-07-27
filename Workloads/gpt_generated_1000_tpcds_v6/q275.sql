WITH base AS (
    SELECT
        s.s_store_id,
        s.s_manager,
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        cp.cp_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS avg_store_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
        MIN(i.inv_quantity_on_hand) AS min_inventory,
        MAX(cs.cs_ext_ship_cost) AS max_ship_cost
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_manager = 'John Mccoy'
      AND cp.cp_type = 'PROMO'
      AND i.inv_quantity_on_hand > 0
    GROUP BY
        s.s_store_id,
        s.s_manager,
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        cp.cp_type
)
SELECT
    b.s_store_id,
    b.s_manager,
    b.d_year,
    b.d_month_seq,
    b.cp_department,
    b.cp_type,
    b.total_net_paid,
    b.avg_store_sales_price,
    b.orders_cnt,
    b.min_inventory,
    b.max_ship_cost,
    SUM(b.total_net_paid) OVER (PARTITION BY b.s_store_id ORDER BY b.d_month_seq ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
    (
        SELECT AVG(cs2.cs_wholesale_cost)
        FROM catalog_sales cs2
        JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
        WHERE d2.d_year = 2001
    ) AS avg_wholesale_cost_2001
FROM base b
ORDER BY b.s_store_id, b.d_month_seq
LIMIT 100
