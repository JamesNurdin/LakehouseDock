WITH agg AS (
    SELECT
        d.d_year,
        s.s_store_name,
        w.w_warehouse_name,
        cd.cd_credit_rating,
        r.r_reason_desc,
        SUM(ws.ws_ext_sales_price)                         AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0))               AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number)                 AS order_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND w.w_state = 'CA'
      AND s.s_number_employees > 250
      AND cd.cd_credit_rating = 'Good'
    GROUP BY d.d_year, s.s_store_name, w.w_warehouse_name, cd.cd_credit_rating, r.r_reason_desc
),
ranked AS (
    SELECT
        a.*,
        ROW_NUMBER() OVER (ORDER BY a.total_sales DESC)                     AS global_row_num,
        ROW_NUMBER() OVER (PARTITION BY a.d_year ORDER BY a.total_sales DESC) AS rank_in_year,
        a.total_sales / NULLIF(a.order_cnt, 0)                               AS avg_sales_per_order
    FROM agg a
    WHERE a.total_sales > 10000
)
SELECT
    d_year,
    s_store_name,
    w_warehouse_name,
    cd_credit_rating,
    r_reason_desc,
    total_sales,
    total_return_amount,
    order_cnt,
    avg_sales_per_order,
    global_row_num,
    rank_in_year
FROM ranked
WHERE rank_in_year <= 5
ORDER BY d_year, total_sales DESC
LIMIT 100
