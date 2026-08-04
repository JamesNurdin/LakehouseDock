WITH store_metrics AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        SUM(CASE WHEN r.r_reason_desc LIKE '%duplicate%' THEN 1 ELSE 0 END) AS duplicate_reason_cnt
    FROM store_sales ss
    RIGHT OUTER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
       AND cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
      AND s.s_state = 'CA'
      AND r.r_reason_desc IS NOT NULL
    GROUP BY s.s_store_id, s.s_store_name, d.d_year
),
overall AS (
    SELECT AVG(total_sales) AS avg_sales FROM store_metrics
)
SELECT
    sm.s_store_id,
    sm.s_store_name,
    sm.d_year,
    sm.total_sales,
    sm.total_catalog_returns,
    sm.total_web_returns,
    sm.duplicate_reason_cnt,
    CASE WHEN sm.distinct_tickets = 0 THEN 0 ELSE sm.total_sales / sm.distinct_tickets END AS sales_per_ticket,
    ROW_NUMBER() OVER (ORDER BY sm.total_sales DESC) AS sales_rank
FROM store_metrics sm
CROSS JOIN overall o
WHERE sm.total_sales > o.avg_sales * 1.2
ORDER BY sm.total_sales DESC
LIMIT 100
