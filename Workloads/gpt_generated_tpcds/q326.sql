WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        ds.d_year,
        ds.d_month_seq,
        ds.d_date,
        format_datetime(cast(ds.d_date AS timestamp), '%Y-%m') AS year_month,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ds.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        ds.d_year,
        ds.d_month_seq,
        ds.d_date,
        format_datetime(cast(ds.d_date AS timestamp), '%Y-%m')
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        dr.d_year,
        dr.d_month_seq,
        dr.d_date,
        format_datetime(cast(dr.d_date AS timestamp), '%Y-%m') AS year_month,
        SUM(sr.sr_return_amt) AS total_returns,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE dr.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        dr.d_year,
        dr.d_month_seq,
        dr.d_date,
        format_datetime(cast(dr.d_date AS timestamp), '%Y-%m')
)
SELECT
    sa.s_store_name,
    sa.year_month,
    sa.total_sales,
    sa.total_net_paid,
    sa.total_net_profit,
    COALESCE(ra.total_returns, 0) AS total_returns,
    COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
    CASE WHEN sa.total_sales > 0 THEN ra.total_returns / sa.total_sales ELSE 0 END AS return_amount_ratio,
    CASE WHEN sa.total_quantity > 0 THEN ra.total_return_quantity / sa.total_quantity ELSE 0 END AS return_quantity_ratio
FROM sales_agg sa
LEFT JOIN returns_agg ra
    ON sa.s_store_sk = ra.s_store_sk
    AND sa.year_month = ra.year_month
ORDER BY sa.s_store_name, sa.year_month
