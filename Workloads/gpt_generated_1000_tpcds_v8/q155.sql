WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_description,
        sm.sm_ship_mode_id,
        td.t_hour
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_hour BETWEEN 6 AND 12
      AND (cp.cp_description LIKE '%Special%' OR cp.cp_description LIKE '%Limited%')
),
returns_base AS (
    SELECT
        cr.cr_order_number,
        cr.cr_net_loss,
        r.r_reason_desc,
        r.r_reason_id,
        sm.sm_ship_mode_id AS ret_ship_mode_id
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)time')
)
SELECT
    sb.cp_department,
    sb.sm_ship_mode_id,
    CONCAT(sb.cp_department, '-', sb.sm_ship_mode_id) AS dept_ship,
    CASE WHEN SUM(sb.cs_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
    SUM(sb.cs_net_paid) AS total_sales_paid,
    SUM(COALESCE(rb.cr_net_loss, 0)) AS total_return_loss,
    COUNT(DISTINCT sb.cs_order_number) AS sales_orders,
    COUNT(DISTINCT rb.cr_order_number) AS return_orders,
    REGEXP_EXTRACT(MIN(rb.r_reason_desc), '(\\w+) time', 1) AS common_time_reason_word
FROM sales_base sb
LEFT JOIN returns_base rb
    ON sb.cs_order_number = rb.cr_order_number
GROUP BY
    sb.cp_department,
    sb.sm_ship_mode_id,
    CONCAT(sb.cp_department, '-', sb.sm_ship_mode_id)
ORDER BY total_sales_paid DESC
LIMIT 20
