WITH joined AS (
    SELECT
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        ss.ss_quantity AS ss_quantity,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        cp.cp_department,
        hd.hd_buy_potential,
        sm.sm_contract,
        ca.ca_state,
        d.d_fy_year,
        ARRAY[cs.cs_ext_sales_price, ss.ss_ext_sales_price] AS sales_array
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
            AND ss.ss_hdemo_sk = hd.hd_demo_sk
            AND ss.ss_addr_sk = ca.ca_address_sk
    WHERE
        d.d_fy_year = 1912
        AND cp.cp_department = 'Books'
        AND hd.hd_buy_potential IN ('0-500', '501-1000')
        AND sm.sm_contract LIKE 'A5%'
        AND ca.ca_state = 'CA'
)
SELECT
    cp_department,
    hd_buy_potential,
    metric_position,
    SUM(metric_value) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY SUM(metric_value) DESC) AS dept_sales_rank
FROM (
    SELECT
        cp_department,
        hd_buy_potential,
        metric_position,
        metric_value
    FROM joined
    CROSS JOIN UNNEST(sales_array) WITH ORDINALITY AS t(metric_value, metric_position)
) AS unnested
GROUP BY CUBE(cp_department, hd_buy_potential, metric_position)
ORDER BY dept_sales_rank, total_sales DESC
LIMIT 100
