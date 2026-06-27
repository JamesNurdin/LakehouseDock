WITH sales_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq
),
returns_agg AS (
    SELECT
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY s.s_store_name, d.d_year, d.d_month_seq
),
combined AS (
    SELECT
        sa.s_store_name,
        sa.d_year,
        sa.d_month_seq,
        sa.total_sales_amount,
        sa.total_sales_quantity,
        sa.total_discount_amount,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_quantity, 0) AS total_return_quantity,
        sa.total_sales_amount - COALESCE(ra.total_return_amount, 0) AS net_sales_amount,
        (sa.total_sales_amount - COALESCE(ra.total_return_amount, 0)) - sa.total_discount_amount AS net_sales_after_discount
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.s_store_name = ra.s_store_name
       AND sa.d_year = ra.d_year
       AND sa.d_month_seq = ra.d_month_seq
)
SELECT
    c.s_store_name,
    c.d_year,
    c.d_month_seq,
    c.total_sales_amount,
    c.total_sales_quantity,
    c.total_discount_amount,
    c.total_return_amount,
    c.total_return_quantity,
    c.net_sales_amount,
    c.net_sales_after_discount,
    SUM(c.net_sales_amount) OVER (PARTITION BY c.s_store_name ORDER BY c.d_year, c.d_month_seq) AS cumulative_net_sales
FROM combined c
ORDER BY c.net_sales_amount DESC
LIMIT 10
