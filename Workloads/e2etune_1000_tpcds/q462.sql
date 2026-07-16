WITH state_dept_sales AS (
    SELECT
        cc.cc_state AS state,
        cp.cp_department AS department,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_quantity) AS total_qty
    FROM
        catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cc.cc_hours = '8AM-4PM'
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
        AND cc.cc_rec_end_date <= DATE '2000-12-31'
        AND cp.cp_type = 'A'
        AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451200
    GROUP BY
        cc.cc_state,
        cp.cp_department
)
SELECT
    state,
    department,
    total_sales,
    avg_profit,
    order_cnt,
    total_qty,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM state_dept_sales
WHERE total_sales > 1000000
ORDER BY sales_rank
LIMIT 20
