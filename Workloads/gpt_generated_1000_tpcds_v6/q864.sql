WITH sales_agg AS (
    SELECT
        w.w_warehouse_id,
        cp.cp_department,
        cd.cd_gender,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE td.t_hour >= 12
      AND cd.cd_dep_count <= 3
      AND cp.cp_catalog_number IN (4, 8, 16)
      AND w.w_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY w.w_warehouse_id, cp.cp_department, cd.cd_gender
)
SELECT
    sa.cp_department,
    AVG(sa.total_sales) AS avg_sales,
    AVG(sa.total_profit) AS avg_profit,
    COUNT(DISTINCT sa.w_warehouse_id) AS warehouse_count,
    CASE
        WHEN AVG(sa.total_sales) > (SELECT AVG(cs_ext_sales_price) FROM tpcds.catalog_sales) THEN 'High'
        ELSE 'Low'
    END AS sales_level
FROM sales_agg sa
GROUP BY sa.cp_department
HAVING AVG(sa.total_sales) > 20000
ORDER BY avg_sales DESC
