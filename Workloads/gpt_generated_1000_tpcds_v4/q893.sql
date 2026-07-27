WITH agg1 AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        d.d_year,
        SUM(cr.cr_return_amount) AS total_catalog_return,
        SUM(wr.wr_return_amt) AS total_web_return,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_web_orders
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2002
      AND w.w_warehouse_sq_ft > 600000
      AND r.r_reason_desc LIKE '%damaged%'
    GROUP BY w.w_warehouse_name, r.r_reason_desc, d.d_year
)
SELECT
    w_name,
    ROUND(AVG(total_return), 2) AS avg_total_return,
    SUM(distinct_catalog_orders) AS total_distinct_catalog_orders
FROM (
    SELECT
        w_warehouse_name AS w_name,
        (total_catalog_return + total_web_return) AS total_return,
        distinct_catalog_orders
    FROM agg1
) sub
GROUP BY w_name
HAVING AVG(total_return) > 1000
ORDER BY avg_total_return DESC
LIMIT 100
