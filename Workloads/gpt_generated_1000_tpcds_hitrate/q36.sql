WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        d_sold.d_year,
        cp.cp_department,
        cd.cd_gender,
        s.s_state
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2002
      AND cp.cp_department = 'Sports'
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
),
returns_base AS (
    SELECT
        wr.wr_order_number
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d_ret.d_quarter_seq = 14
      AND r.r_reason_desc = 'Damaged'
),
order_intersect AS (
    SELECT cs_order_number AS order_num FROM sales_base WHERE cs_quantity > 5
    INTERSECT
    SELECT cs_order_number AS order_num FROM sales_base WHERE cs_net_paid > 100
)
SELECT
    sb.cs_order_number,
    sb.d_year,
    sb.cp_department,
    SUM(sb.cs_quantity) AS total_quantity,
    AVG(sb.cs_net_paid) AS avg_net_paid,
    COUNT(*) AS sales_count,
    CASE WHEN SUM(sb.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
FROM sales_base sb
WHERE sb.cs_order_number IN (SELECT order_num FROM order_intersect)
GROUP BY sb.cs_order_number, sb.d_year, sb.cp_department
ORDER BY total_quantity DESC
LIMIT 100
