WITH sales_agg AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS warehouse_name,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_net_paid) AS total_paid,
        AVG(cs.cs_ext_ship_cost) AS avg_ship_cost,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_net_profit > 0
      AND cs.cs_ext_ship_cost > 100
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, w.w_warehouse_name
),
store_agg AS (
    SELECT
        d.d_year AS year,
        COUNT(s.s_store_sk) AS stores_closed,
        AVG(s.s_floor_space) AS avg_floor_space
    FROM store s
    JOIN date_dim d ON s.s_closed_date_sk = d.d_date_sk
    WHERE s.s_closed_date_sk IS NOT NULL
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
),
page_agg AS (
    SELECT
        d.d_year AS year,
        COUNT(DISTINCT wp.wp_web_page_sk) AS distinct_pages_accessed
    FROM web_page wp
    JOIN date_dim d ON wp.wp_access_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year
)
SELECT
    s.year,
    s.warehouse_name,
    s.total_profit,
    s.total_paid,
    s.avg_ship_cost,
    s.total_quantity,
    s.avg_discount,
    st.stores_closed,
    st.avg_floor_space,
    p.distinct_pages_accessed
FROM sales_agg s
JOIN store_agg st ON s.year = st.year
JOIN page_agg p ON s.year = p.year
ORDER BY s.total_profit DESC
LIMIT 20
