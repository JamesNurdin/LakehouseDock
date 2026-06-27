WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_paid) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_sales_profit,
        SUM(ss.ss_ext_discount_amt) AS total_discount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
    GROUP BY s.s_store_name, d.d_year, d.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
    GROUP BY s.s_store_name, d.d_year, d.d_moy
)
SELECT
    COALESCE(sa.s_store_name, ra.s_store_name) AS store_name,
    COALESCE(sa.d_year, ra.d_year) AS year,
    COALESCE(sa.d_moy, ra.d_moy) AS month,
    COALESCE(sa.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(sa.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(sa.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    (COALESCE(sa.total_sales_profit, 0) - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    (COALESCE(sa.total_sales_amount, 0) - COALESCE(ra.total_return_amount, 0)) AS net_sales_amount,
    COALESCE(sa.total_discount, 0) AS total_discount
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.s_store_name = ra.s_store_name
   AND sa.d_year = ra.d_year
   AND sa.d_moy = ra.d_moy
ORDER BY store_name, year, month
