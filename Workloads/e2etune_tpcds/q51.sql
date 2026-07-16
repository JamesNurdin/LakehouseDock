WITH sales AS (
    SELECT
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_type,
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_quarter_seq,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_quantity) AS total_qty,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        SUM(cs.cs_coupon_amt) AS total_coupon
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE d.d_year = 2020
      AND cp.cp_type = 'monthly'
      AND p.p_discount_active = 'Y'
      AND t.t_shift = 'Morning'
    GROUP BY
        cp.cp_catalog_page_sk,
        cp.cp_catalog_page_id,
        cp.cp_type,
        p.p_promo_sk,
        p.p_promo_name,
        d.d_year,
        d.d_quarter_seq
),
returns AS (
    SELECT
        cr.cr_catalog_page_sk,
        d.d_year,
        d.d_quarter_seq,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    WHERE d.d_year = 2020
      AND t.t_shift = 'Morning'
    GROUP BY
        cr.cr_catalog_page_sk,
        d.d_year,
        d.d_quarter_seq
)
SELECT
    s.cp_catalog_page_id AS catalog_page_id,
    s.cp_type AS catalog_page_type,
    s.p_promo_name AS promotion_name,
    s.d_year AS year,
    s.d_quarter_seq AS quarter,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_returns,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.total_qty,
    CASE WHEN s.total_qty = 0 THEN 0
         ELSE (COALESCE(r.total_return_qty, 0) * 1.0 / s.total_qty)
    END AS return_rate,
    CASE WHEN s.total_sales = 0 THEN 0
         ELSE (s.total_profit * 1.0 / s.total_sales)
    END AS profit_margin,
    RANK() OVER (PARTITION BY s.d_year, s.d_quarter_seq
                 ORDER BY (s.total_sales - COALESCE(r.total_return_amount, 0)) DESC) AS sales_rank
FROM sales s
LEFT JOIN returns r
    ON s.cp_catalog_page_sk = r.cr_catalog_page_sk
   AND s.d_year = r.d_year
   AND s.d_quarter_seq = r.d_quarter_seq
ORDER BY s.d_year, s.d_quarter_seq, sales_rank
LIMIT 100
