WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_category,
        ds.d_year,
        ds.d_moy,
        sum(ss.ss_ext_sales_price) AS total_sales_amount,
        sum(ss.ss_quantity) AS total_quantity,
        sum(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE ds.d_year = 2020
    GROUP BY s.s_store_sk, s.s_store_name, i.i_category, ds.d_year, ds.d_moy
),
returns_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_category,
        dr.d_year,
        dr.d_moy,
        sum(sr.sr_return_quantity) AS total_return_qty,
        sum(sr.sr_return_amt) AS total_return_amount,
        sum(sr.sr_refunded_cash) AS total_refunded_cash
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE dr.d_year = 2020
    GROUP BY s.s_store_sk, s.s_store_name, i.i_category, dr.d_year, dr.d_moy
)
SELECT
    s.s_store_name,
    s.i_category,
    s.d_year,
    s.d_moy,
    s.total_sales_amount,
    s.total_quantity,
    s.total_net_profit,
    coalesce(r.total_return_qty, 0) AS total_return_qty,
    coalesce(r.total_return_amount, 0) AS total_return_amount,
    coalesce(r.total_refunded_cash, 0) AS total_refunded_cash,
    (coalesce(r.total_return_qty, 0) / nullif(s.total_quantity, 0)) AS return_rate,
    (s.total_sales_amount - coalesce(r.total_return_amount, 0)) AS net_sales_after_returns,
    (s.total_net_profit - coalesce(r.total_refunded_cash, 0)) AS net_profit_after_returns
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.s_store_sk = r.s_store_sk
    AND s.i_category = r.i_category
    AND s.d_year = r.d_year
    AND s.d_moy = r.d_moy
ORDER BY s.total_sales_amount DESC
LIMIT 100
