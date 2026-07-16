WITH sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        d.d_year,
        d.d_month_seq
    FROM catalog_sales cs
    JOIN date_dim d
      ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
),
promo_active AS (
    SELECT
        p.p_promo_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
),
agg AS (
    SELECT
        cp.cp_department,
        w.w_city,
        s.d_year,
        s.d_month_seq,
        SUM(s.cs_net_paid) AS total_net_paid,
        SUM(s.cs_net_profit) AS total_net_profit,
        AVG(s.cs_ext_discount_amt) AS avg_discount_amount,
        COUNT(DISTINCT s.cs_catalog_page_sk) AS distinct_pages_sold
    FROM sales s
    JOIN catalog_page cp
      ON s.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON s.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promo_active pa
      ON s.cs_promo_sk = pa.p_promo_sk
    WHERE cp.cp_type = 'monthly'
      AND w.w_state = 'CA'
    GROUP BY
        cp.cp_department,
        w.w_city,
        s.d_year,
        s.d_month_seq
)
SELECT
    cp_department,
    w_city,
    d_year,
    d_month_seq,
    total_net_paid,
    total_net_profit,
    avg_discount_amount,
    distinct_pages_sold,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank_by_year
FROM agg
ORDER BY
    d_year,
    d_month_seq,
    total_net_profit DESC
LIMIT 100
