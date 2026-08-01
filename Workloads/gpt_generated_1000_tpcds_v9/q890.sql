WITH sales_base AS (
    SELECT
        cc.cc_name,
        cc.cc_call_center_sk,
        cc.cc_state,
        cc.cc_employees,
        cc.cc_rec_start_date,
        cp.cp_department,
        w.w_warehouse_name,
        w.w_state AS w_state,
        t_cs.t_hour,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_fee,
        ss.ss_net_paid,
        ss.ss_quantity,
        cr.cr_reason_sk
    FROM
        catalog_sales cs
        INNER JOIN call_center cc
            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        INNER JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        INNER JOIN time_dim t_cs
            ON cs.cs_sold_time_sk = t_cs.t_time_sk
        INNER JOIN customer_demographics cd_bill
            ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
        INNER JOIN catalog_returns cr
            ON cr.cr_order_number = cs.cs_order_number
        INNER JOIN time_dim t_cr
            ON cr.cr_returned_time_sk = t_cr.t_time_sk
        INNER JOIN customer_demographics cd_refunded
            ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        INNER JOIN store_sales ss
            ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
        INNER JOIN time_dim t_ss
            ON ss.ss_sold_time_sk = t_ss.t_time_sk
    WHERE
        cc.cc_state = 'CA'
        AND cc.cc_employees > 1000000
        AND cc.cc_rec_start_date >= DATE '2000-01-01'
        AND cc.cc_rec_start_date <= DATE '2005-12-31'
        AND cp.cp_department = 'Electronics'
        AND t_cs.t_hour BETWEEN 9 AND 17
        AND cd_bill.cd_education_status = '4 yr Degree'
        AND cd_bill.cd_dep_employed_count >= 3
        AND w.w_state = 'CA'
        AND ss.ss_quantity > 5
        AND cr.cr_return_amount > 100
        AND cs.cs_quantity > (
            SELECT AVG(cs3.cs_quantity)
            FROM catalog_sales cs3
            WHERE cs3.cs_call_center_sk = cs.cs_call_center_sk
        )
        AND EXISTS (
            SELECT 1
            FROM reason r
            WHERE r.r_reason_sk = cr.cr_reason_sk
              AND r.r_reason_desc LIKE '%color%'
        )
),
agg AS (
    SELECT
        sb.cc_name,
        sb.cc_call_center_sk,
        sb.w_warehouse_name,
        sb.cp_department,
        sb.t_hour,
        SUM(sb.cs_net_paid) AS total_sales_net_paid,
        SUM(sb.cr_return_amount) AS total_return_amount,
        SUM(sb.cr_net_loss) AS total_net_loss,
        AVG(sb.ss_net_paid) AS avg_store_sales_net_paid,
        COUNT(DISTINCT sb.cs_order_number) AS distinct_orders,
        MIN(sb.cr_fee) AS min_return_fee,
        MAX(sb.cr_fee) AS max_return_fee
    FROM sales_base sb
    GROUP BY
        sb.cc_name,
        sb.cc_call_center_sk,
        sb.w_warehouse_name,
        sb.cp_department,
        sb.t_hour
)
SELECT
    a.cc_name,
    a.w_warehouse_name,
    a.cp_department,
    a.t_hour,
    a.total_sales_net_paid,
    a.total_return_amount,
    a.total_net_loss,
    a.avg_store_sales_net_paid,
    a.distinct_orders,
    a.min_return_fee,
    a.max_return_fee,
    (
        SELECT MAX(cs2.cs_ext_sales_price)
        FROM catalog_sales cs2
        WHERE cs2.cs_call_center_sk = a.cc_call_center_sk
    ) AS max_ext_sales_price_by_cc,
    ROW_NUMBER() OVER (PARTITION BY a.cc_name ORDER BY a.total_sales_net_paid DESC) AS sales_rank_by_cc,
    ROW_NUMBER() OVER (ORDER BY a.total_sales_net_paid DESC) AS overall_sales_rank
FROM agg a
ORDER BY a.total_sales_net_paid DESC
LIMIT 100
