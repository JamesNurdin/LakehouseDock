WITH page_stats AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_department,
        cp.cp_catalog_number,
        cp.cp_description,
        MAX(cs.cs_ext_discount_amt) AS max_discount_per_page
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cs.cs_ext_ship_cost > 500
    GROUP BY cp.cp_catalog_page_sk, cp.cp_department, cp.cp_catalog_number, cp.cp_description
)
SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    t.t_hour,
    COUNT(cs.cs_order_number) AS orders,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(cs.cs_ext_ship_cost) AS min_ship_cost,
    MAX(cs.cs_ext_list_price) AS max_list_price,
    (SELECT MAX(p.max_discount_per_page)
     FROM page_stats p
     WHERE p.cp_catalog_page_sk = cs.cs_catalog_page_sk) AS page_max_discount
FROM catalog_sales cs
JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
WHERE
    cs.cs_ext_ship_cost BETWEEN 600 AND 2000
    AND cs.cs_ext_list_price > 1000
    AND cp.cp_catalog_number IN (7, 14, 20)
    AND cp.cp_end_date_sk >= 2450900
    AND t.t_second IN (4, 7, 16)
    AND cs.cs_quantity >= 2
GROUP BY
    cp.cp_department,
    cp.cp_catalog_number,
    t.t_hour,
    cs.cs_catalog_page_sk
HAVING
    SUM(cs.cs_net_paid) > (
        SELECT AVG(cs2.cs_net_paid)
        FROM catalog_sales cs2
    )
ORDER BY
    total_net_paid DESC,
    orders DESC
LIMIT 100
