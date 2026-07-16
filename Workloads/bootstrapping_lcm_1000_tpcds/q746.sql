WITH sales_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        d.d_date,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_returns,
        SUM(ss.ss_ext_sales_price) - COALESCE(SUM(cr.cr_return_amount), 0) AS net_sales
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
        AND s.s_closed_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        d.d_date,
        hd.hd_buy_potential
)
SELECT
    s_store_id,
    s_store_name,
    d_date,
    hd_buy_potential,
    total_sales,
    total_returns,
    net_sales,
    ROW_NUMBER() OVER (ORDER BY net_sales DESC) AS sales_rank
FROM sales_returns
ORDER BY sales_rank
LIMIT 100
