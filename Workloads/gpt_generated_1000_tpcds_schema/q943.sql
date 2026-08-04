WITH base1 AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_quantity,
        ti.t_hour,
        i.i_category,
        i.i_units,
        ca.ca_state,
        s.s_store_name,
        s.s_market_desc,
        s.s_gmt_offset
    FROM store_sales ss
    JOIN time_dim ti ON ss.ss_sold_time_sk = ti.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_ext_wholesale_cost > 500
      AND i.i_units IN ('Bundle', 'Case')
      AND ca.ca_state = 'CA'
      AND s.s_gmt_offset BETWEEN -5.00 AND 5.00
),

base2 AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_ext_wholesale_cost,
        ss.ss_quantity,
        ti.t_hour,
        i.i_category,
        i.i_units,
        ca.ca_state,
        s.s_store_name,
        s.s_market_desc,
        s.s_gmt_offset
    FROM store_sales ss
    JOIN time_dim ti ON ss.ss_sold_time_sk = ti.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ss.ss_ext_list_price < 1000
      AND i.i_category = 'Electronics'
      AND ca.ca_location_type = 'condo'
      AND s.s_state = 'TX'
),

unioned AS (
    SELECT * FROM base1
    UNION DISTINCT
    SELECT * FROM base2
),

full_joined AS (
    SELECT
        u.*, 
        s2.s_store_name AS extra_store_name,
        s2.s_market_desc AS extra_market_desc
    FROM unioned u
    FULL OUTER JOIN store s2
        ON u.ss_store_sk = s2.s_store_sk
)
SELECT
    f.s_store_name,
    f.ca_state,
    f.i_category,
    f.t_hour,
    SUM(f.ss_ext_sales_price) AS total_sales,
    CASE
        WHEN SUM(f.ss_ext_sales_price) > 100000 THEN 'High'
        WHEN SUM(f.ss_ext_sales_price) > 50000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_level,
    ROW_NUMBER() OVER (PARTITION BY f.i_category ORDER BY SUM(f.ss_ext_sales_price) DESC) AS category_rank
FROM full_joined f
WHERE f.t_hour BETWEEN 8 AND 20
GROUP BY f.s_store_name, f.ca_state, f.i_category, f.t_hour, f.extra_market_desc
ORDER BY total_sales DESC
LIMIT 100
