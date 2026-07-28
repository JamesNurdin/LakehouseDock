WITH sales_base AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS warehouse_name,
        p.p_promo_name AS promo_name,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_description,
        cp.cp_type,
        CASE WHEN regexp_like(cp.cp_description, '(?i)discount') THEN 1 ELSE 0 END AS has_discount,
        regexp_extract(cp.cp_description, '(\\d+)', 1) AS desc_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_type LIKE 'A%'
      AND w.w_warehouse_name LIKE '%Warehouse%'
      AND d.d_year BETWEEN 2000 AND 2002
)
SELECT
    sb.year,
    sb.warehouse_name,
    sb.promo_name,
    SUM(sb.cs_ext_sales_price) AS total_sales,
    SUM(sb.cs_net_profit) AS total_profit,
    AVG(sb.cs_net_profit) AS avg_profit,
    SUM(sb.has_discount) AS discount_page_cnt,
    COUNT(*) AS sales_cnt,
    CONCAT(sb.warehouse_name, ' (', SUBSTR(sb.promo_name, 1, 5), ')') AS warehouse_promo_display,
    ROW_NUMBER() OVER (PARTITION BY sb.year ORDER BY SUM(sb.cs_ext_sales_price) DESC) AS sales_rank
FROM sales_base sb
GROUP BY
    sb.year,
    sb.warehouse_name,
    sb.promo_name
ORDER BY sb.year DESC, total_sales DESC
LIMIT 100
