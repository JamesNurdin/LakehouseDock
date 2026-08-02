/* Goal: Calculate total sales, average quantity, and distinct order count by year, quarter, ship type, and store state for selected ship modes and periods */
WITH union_sales AS (
    SELECT
        sold_d.d_year,
        sold_d.d_quarter_name,
        sm.sm_type,
        st.s_state,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim sold_d ON cs.cs_sold_date_sk = sold_d.d_date_sk
    JOIN date_dim ship_d ON cs.cs_ship_date_sk = ship_d.d_date_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store st ON st.s_closed_date_sk = ship_d.d_date_sk
    WHERE
        sold_d.d_year = 1998
        AND ship_d.d_quarter_name = '1904Q1'
        AND sm.sm_code = 'AIR'
        AND st.s_state = 'CA'
        AND cs.cs_quantity > 5
        AND cs.cs_ext_sales_price > 500

    UNION

    SELECT
        sold_d.d_year,
        sold_d.d_quarter_name,
        sm.sm_type,
        st.s_state,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim sold_d ON cs.cs_sold_date_sk = sold_d.d_date_sk
    JOIN date_dim ship_d ON cs.cs_ship_date_sk = ship_d.d_date_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store st ON st.s_closed_date_sk = ship_d.d_date_sk
    WHERE
        sold_d.d_year = 1999
        AND ship_d.d_quarter_name = '1904Q2'
        AND sm.sm_code = 'SEA'
        AND st.s_state = 'TX'
        AND cs.cs_quantity > 10
        AND cs.cs_ext_sales_price > 700
)
SELECT
    d_year AS year,
    d_quarter_name AS quarter,
    sm_type AS ship_type,
    s_state AS store_state,
    SUM(cs_ext_sales_price) AS total_sales,
    AVG(cs_quantity) AS avg_quantity,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM union_sales
GROUP BY d_year, d_quarter_name, sm_type, s_state
ORDER BY total_sales DESC
