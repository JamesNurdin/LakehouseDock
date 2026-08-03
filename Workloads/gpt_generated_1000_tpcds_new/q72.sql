WITH base AS (
    SELECT
        cu.c_customer_id,
        dd.d_year,
        SUM(cs.cs_net_paid) AS total_catalog_paid,
        SUM(ss.ss_net_paid) AS total_store_paid,
        SUM(wr.wr_refunded_cash) AS total_refunded_cash,
        SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(wr.wr_net_loss) AS total_profit
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer cu
        ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd
        ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = cu.c_customer_sk
        AND ss.ss_sold_date_sk = dd.d_date_sk
    JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = cu.c_customer_sk
        AND wr.wr_returned_date_sk = dd.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE dd.d_year = 2001
      AND cu.c_birth_month = 7
      AND cp.cp_department = 'Sports'
      AND wp.wp_image_count > 2
      AND r.r_reason_desc LIKE '%defect%'
    GROUP BY cu.c_customer_id, dd.d_year
)
SELECT
    c_customer_id,
    d_year,
    total_catalog_paid,
    total_store_paid,
    total_refunded_cash,
    total_profit,
    (total_catalog_paid + total_store_paid - total_refunded_cash) AS total_revenue,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_catalog_paid + total_store_paid - total_refunded_cash) DESC) AS revenue_rank,
    ROW_NUMBER() OVER (ORDER BY (total_catalog_paid + total_store_paid - total_refunded_cash) DESC) AS overall_row_num
FROM base
ORDER BY total_revenue DESC
LIMIT 100
