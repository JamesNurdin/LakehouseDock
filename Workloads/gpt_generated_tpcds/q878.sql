WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        sum(ss.ss_ext_sales_price) AS total_sales,
        sum(ss.ss_ext_discount_amt) AS total_discount,
        sum(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        sum(sr.sr_return_amt) AS total_returns
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
),
promo_rank AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        p.p_promo_name,
        sum(ss.ss_ext_sales_price) AS promo_sales,
        row_number() OVER (
            PARTITION BY s.s_store_id, d.d_year, d.d_month_seq
            ORDER BY sum(ss.ss_ext_sales_price) DESC
        ) AS rn
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq, p.p_promo_name
),
top_promo AS (
    SELECT
        s_store_id,
        s_store_name,
        d_year,
        d_month_seq,
        p_promo_name,
        promo_sales
    FROM promo_rank
    WHERE rn = 1
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.total_sales,
    sa.total_discount,
    sa.total_profit,
    coalesce(ra.total_returns, 0) AS total_returns,
    (sa.total_sales - coalesce(ra.total_returns, 0)) AS net_revenue,
    CASE WHEN sa.total_sales > 0 THEN coalesce(ra.total_returns, 0) / sa.total_sales ELSE 0 END AS return_rate,
    tp.p_promo_name AS top_promo_name,
    tp.promo_sales AS top_promo_sales
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_id = ra.s_store_id
    AND sa.s_store_name = ra.s_store_name
    AND sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
LEFT JOIN top_promo tp
    ON sa.s_store_id = tp.s_store_id
    AND sa.d_year = tp.d_year
    AND sa.d_month_seq = tp.d_month_seq
WHERE sa.d_year = 2001
ORDER BY net_revenue DESC
LIMIT 20
