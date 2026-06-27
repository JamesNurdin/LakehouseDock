WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq
),
store_returns_agg AS (
    SELECT
        s.s_store_sk,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_net_loss) AS total_store_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
    GROUP BY s.s_store_sk, d_ret.d_year, d_ret.d_month_seq
),
catalog_returns_agg AS (
    SELECT
        d_cat.d_year,
        d_cat.d_month_seq,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d_cat ON cr.cr_returned_date_sk = d_cat.d_date_sk
    WHERE d_cat.d_year = 2001
    GROUP BY d_cat.d_year, d_cat.d_month_seq
)
SELECT
    sa.s_store_name,
    sa.d_year,
    sa.d_month_seq,
    sa.total_sales,
    sa.total_profit,
    sa.total_discount,
    COALESCE(sr.total_store_return_amt, 0) AS total_store_return_amt,
    COALESCE(sr.total_store_net_loss, 0) AS total_store_net_loss,
    COALESCE(cr.total_catalog_return_amount, 0) AS total_catalog_return_amount,
    COALESCE(cr.total_catalog_net_loss, 0) AS total_catalog_net_loss,
    (sa.total_sales - COALESCE(sr.total_store_return_amt, 0) - COALESCE(cr.total_catalog_return_amount, 0)) AS net_revenue
FROM sales_agg sa
LEFT JOIN store_returns_agg sr
    ON sa.s_store_sk = sr.s_store_sk
   AND sa.d_year = sr.d_year
   AND sa.d_month_seq = sr.d_month_seq
LEFT JOIN catalog_returns_agg cr
    ON sa.d_year = cr.d_year
   AND sa.d_month_seq = cr.d_month_seq
ORDER BY net_revenue DESC
