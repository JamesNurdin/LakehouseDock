WITH sales_agg AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cs.cs_promo_sk, d.d_year
),
store_agg AS (
    SELECT
        ss.ss_promo_sk AS promo_sk,
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS net_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss.ss_promo_sk, d.d_year
),
returns_agg AS (
    SELECT
        cs.cs_promo_sk AS promo_sk,
        d.d_year AS year,
        SUM(cr.cr_net_loss) AS net_loss,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cs.cs_promo_sk, d.d_year
),
promo_years AS (
    SELECT promo_sk, year FROM sales_agg
    UNION
    SELECT promo_sk, year FROM store_agg
    UNION
    SELECT promo_sk, year FROM returns_agg
)
SELECT
    p.p_promo_id,
    py.year,
    COALESCE(s.net_profit, 0) + COALESCE(st.net_profit, 0) AS total_net_profit,
    COALESCE(r.net_loss, 0) AS total_net_loss,
    COALESCE(s.sales_cnt, 0) + COALESCE(st.sales_cnt, 0) AS total_sales_cnt,
    CASE
        WHEN (COALESCE(s.sales_cnt, 0) + COALESCE(st.sales_cnt, 0)) > 0
        THEN (COALESCE(s.net_profit, 0) + COALESCE(st.net_profit, 0)) /
             (COALESCE(s.sales_cnt, 0) + COALESCE(st.sales_cnt, 0))
        ELSE NULL
    END AS avg_net_profit_per_sale
FROM promo_years py
JOIN promotion p
    ON py.promo_sk = p.p_promo_sk
LEFT JOIN sales_agg s
    ON py.promo_sk = s.promo_sk AND py.year = s.year
LEFT JOIN store_agg st
    ON py.promo_sk = st.promo_sk AND py.year = st.year
LEFT JOIN returns_agg r
    ON py.promo_sk = r.promo_sk AND py.year = r.year
ORDER BY total_net_profit DESC
LIMIT 10
