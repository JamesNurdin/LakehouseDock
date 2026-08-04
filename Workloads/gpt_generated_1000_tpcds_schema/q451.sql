WITH sales_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE cs_order_number NOT IN (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_quantity > 500
    )
)
SELECT *
FROM (
    SELECT
        w.w_warehouse_name,
        cp.cp_department,
        td.t_sub_shift,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(*) AS order_cnt,
        MIN(cs.cs_ext_ship_cost) AS min_ship,
        MAX(cs.cs_ext_ship_cost) AS max_ship
    FROM sales_sample cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(
        MAP(
            ARRAY['quantity','list_price'],
            ARRAY[CAST(cs.cs_quantity AS double), CAST(cs.cs_list_price AS double)]
        )
    ) AS u(k, v)
    WHERE cp.cp_catalog_number = 12
      AND cp.cp_start_date_sk BETWEEN 2450800 AND 2450900
      AND td.t_sub_shift = 'morning'
      AND w.w_county = 'Walker County'
    GROUP BY w.w_warehouse_name, cp.cp_department, td.t_sub_shift
    HAVING SUM(cs.cs_ext_sales_price) > 20000

    UNION DISTINCT

    SELECT
        w.w_warehouse_name,
        cp.cp_department,
        td.t_sub_shift,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(*) AS order_cnt,
        MIN(cs.cs_ext_ship_cost) AS min_ship,
        MAX(cs.cs_ext_ship_cost) AS max_ship
    FROM sales_sample cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    CROSS JOIN UNNEST(
        MAP(
            ARRAY['quantity','list_price'],
            ARRAY[CAST(cs.cs_quantity AS double), CAST(cs.cs_list_price AS double)]
        )
    ) AS u(k, v)
    WHERE cp.cp_catalog_number = 18
      AND cp.cp_end_date_sk BETWEEN 2451000 AND 2451100
      AND td.t_sub_shift = 'evening'
      AND w.w_county = 'Marshall County'
    GROUP BY w.w_warehouse_name, cp.cp_department, td.t_sub_shift
    HAVING SUM(cs.cs_ext_sales_price) > 15000
) agg
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
