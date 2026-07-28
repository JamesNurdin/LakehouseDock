WITH q1 AS (
    SELECT
        d.d_year,
        w.w_city,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        SUM(cs.cs_ext_sales_price)          AS total_sales,
        AVG(ss.ss_net_paid)                 AS avg_store_paid,
        COUNT(DISTINCT cs.cs_order_number)  AS order_cnt,
        SUM(cr.cr_return_amount)            AS total_catalog_return,
        SUM(wr.wr_return_amt)               AS total_web_return,
        MIN(d.d_date)                       AS start_date,
        MAX(d.d_date)                       AS end_date
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
           AND wr.wr_web_page_sk = wp.wp_web_page_sk
           AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-03-31'
      AND w.w_city = 'Shiloh'
      AND p.p_channel_tv = 'Y'
    GROUP BY d.d_year, w.w_city,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END
),
q2 AS (
    SELECT
        d.d_year,
        w.w_city,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
        SUM(cs.cs_ext_sales_price)          AS total_sales,
        AVG(ss.ss_net_paid)                 AS avg_store_paid,
        COUNT(DISTINCT cs.cs_order_number)  AS order_cnt,
        SUM(cr.cr_return_amount)            AS total_catalog_return,
        SUM(wr.wr_return_amt)               AS total_web_return,
        MIN(d.d_date)                       AS start_date,
        MAX(d.d_date)                       AS end_date
    FROM date_dim d
    JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
           AND wr.wr_web_page_sk = wp.wp_web_page_sk
           AND wr.wr_reason_sk = r.r_reason_sk
    WHERE d.d_date BETWEEN DATE '2001-04-01' AND DATE '2001-06-30'
      AND w.w_city = 'Riverside'
      AND p.p_channel_email = 'Y'
    GROUP BY d.d_year, w.w_city,
        CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END
)
SELECT *
FROM q1
UNION ALL
SELECT *
FROM q2
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
