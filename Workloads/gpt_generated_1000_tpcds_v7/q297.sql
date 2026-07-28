WITH base AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_name,
        p.p_promo_name,
        cp.cp_department,
        sm.sm_type,
        r_cr.r_reason_desc,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cr.cr_return_amount) AS total_returns,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(wr.wr_return_amt) AS web_return_amt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        MIN(cs.cs_ext_sales_price) AS min_sales,
        MAX(cs.cs_ext_sales_price) AS max_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_item_sk = cs.cs_item_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2002
      AND cp.cp_department = 'Electronics'
      AND p.p_promo_name = 'Holiday Discount'
      AND sm.sm_type = 'AIR'
      AND s.s_state = 'CA'
      AND r_cr.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY d.d_year, d.d_month_seq, s.s_store_name, p.p_promo_name,
             cp.cp_department, sm.sm_type, r_cr.r_reason_desc
)
SELECT
    *,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_year,
    RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM base
ORDER BY d_year, d_month_seq
LIMIT 100
