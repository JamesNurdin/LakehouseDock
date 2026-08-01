WITH
    ss_agg AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_customer_sk,
            ss.ss_sold_time_sk,
            SUM(ss.ss_ext_sales_price) AS sum_sales,
            SUM(ss.ss_ext_discount_amt) AS sum_discount,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        TABLESAMPLE BERNOULLI (10)
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE ss.ss_quantity > 1
          AND ss.ss_coupon_amt > 0
          AND t.t_hour BETWEEN 9 AND 18
        GROUP BY ss.ss_sold_date_sk, ss.ss_customer_sk, ss.ss_sold_time_sk
    ),
    ws_agg AS (
        SELECT
            ws.ws_sold_date_sk,
            ws.ws_bill_customer_sk,
            ws.ws_sold_time_sk,
            ws.ws_warehouse_sk,
            ws.ws_web_page_sk,
            SUM(ws.ws_ext_sales_price) AS sum_web_sales,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
        WHERE ws.ws_quantity > 1
          AND t2.t_hour BETWEEN 9 AND 18
        GROUP BY ws.ws_sold_date_sk, ws.ws_bill_customer_sk, ws.ws_sold_time_sk, ws.ws_warehouse_sk, ws.ws_web_page_sk
    ),
    cr_agg AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_refunded_customer_sk,
            cr.cr_catalog_page_sk,
            cr.cr_reason_sk,
            SUM(cr.cr_return_amount) AS sum_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns cr
        GROUP BY cr.cr_returned_date_sk, cr.cr_refunded_customer_sk, cr.cr_catalog_page_sk, cr.cr_reason_sk
    ),
    wr_agg AS (
        SELECT
            wr.wr_returned_date_sk,
            wr.wr_refunded_customer_sk,
            SUM(wr.wr_return_amt) AS sum_web_return_amt,
            COUNT(*) AS web_return_cnt
        FROM web_returns wr
        GROUP BY wr.wr_returned_date_sk, wr.wr_refunded_customer_sk
    ),
    intersected_customers AS (
        SELECT ss_customer_sk AS cust_sk FROM ss_agg
        INTERSECT
        SELECT ws_bill_customer_sk FROM ws_agg
    ),
    union_sales AS (
        SELECT
            ss.ss_sold_date_sk AS sold_date_sk,
            ss.ss_customer_sk AS customer_sk,
            ss.sum_sales AS total_amount,
            ss.sum_discount AS total_discount,
            ss.sales_cnt AS transaction_cnt,
            'store' AS sales_channel,
            ss.ss_sold_time_sk AS time_sk,
            NULL AS warehouse_sk,
            NULL AS web_page_sk
        FROM ss_agg ss
        UNION
        SELECT
            ws.ws_sold_date_sk AS sold_date_sk,
            ws.ws_bill_customer_sk AS customer_sk,
            ws.sum_web_sales AS total_amount,
            0.0 AS total_discount,
            ws.web_sales_cnt AS transaction_cnt,
            'web' AS sales_channel,
            ws.ws_sold_time_sk AS time_sk,
            ws.ws_warehouse_sk AS warehouse_sk,
            ws.ws_web_page_sk AS web_page_sk
        FROM ws_agg ws
    )
SELECT
    d.d_date,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    w.w_warehouse_name,
    cp.cp_catalog_number,
    r.r_reason_desc,
    us.sales_channel,
    us.total_amount,
    us.total_discount,
    us.transaction_cnt,
    ROW_NUMBER() OVER (ORDER BY us.total_amount DESC) AS global_rn,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
          AND wr2.wr_returned_date_sk = d.d_date_sk
    ) AS web_return_cnt,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM cr_agg cr2
            WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
              AND cr2.cr_returned_date_sk = d.d_date_sk
              AND cr2.sum_return_amount > 500
        ) THEN 'High Return'
        ELSE 'Low Return'
    END AS return_risk_flag
FROM union_sales us
JOIN date_dim d
    ON us.sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON us.time_sk = t.t_time_sk
JOIN customer c
    ON us.customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN warehouse w
    ON us.warehouse_sk = w.w_warehouse_sk
LEFT JOIN cr_agg cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
   AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp
    ON us.web_page_sk = wp.wp_web_page_sk
WHERE d.d_year = 1999
  AND cd.cd_gender = 'M'
  AND hd.hd_buy_potential = '1001-5000'
  AND (us.sales_channel = 'store' OR w.w_state = 'CA')
  AND cp.cp_department = 'Electronics'
  AND r.r_reason_desc = 'Damaged'
  AND t.t_hour BETWEEN 9 AND 18
  AND us.customer_sk IN (SELECT cust_sk FROM intersected_customers)
  AND NOT EXISTS (
        SELECT 1
        FROM wr_agg wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
          AND wr.wr_returned_date_sk = d.d_date_sk
          AND wr.sum_web_return_amt > 1000
    )
ORDER BY us.total_amount DESC
LIMIT 100
