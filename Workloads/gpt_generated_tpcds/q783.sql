WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        p.p_promo_sk,
        p.p_promo_name,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_txns
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY s.s_store_sk, d.d_year, d.d_month_seq, p.p_promo_sk, p.p_promo_name, i.i_category
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        d.d_year AS d_year,
        d.d_month_seq AS d_month_seq,
        i.i_category,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY s.s_store_sk, d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.p_promo_name,
    sa.i_category,
    sa.total_sales,
    sa.total_discount,
    sa.total_net_profit,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (
        PARTITION BY sa.d_year, sa.d_month_seq
        ORDER BY (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) DESC
    ) AS profit_rank
FROM sales_agg sa
JOIN store s
    ON sa.s_store_sk = s.s_store_sk
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.d_year = ra.d_year
    AND sa.d_month_seq = ra.d_month_seq
    AND sa.i_category = ra.i_category
ORDER BY sa.d_year, sa.d_month_seq, net_profit_after_returns DESC
LIMIT 100
