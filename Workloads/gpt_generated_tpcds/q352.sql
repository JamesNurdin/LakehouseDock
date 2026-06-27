WITH sales_agg AS (
    SELECT
        store.s_store_sk,
        store.s_store_name,
        date_dim.d_year,
        date_dim.d_moy,
        sum(store_sales.ss_net_paid) AS total_sales,
        sum(store_sales.ss_ext_discount_amt) AS total_discount,
        count(*) AS sales_cnt
    FROM store_sales
    JOIN store ON store_sales.ss_store_sk = store.s_store_sk
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY store.s_store_sk, store.s_store_name, date_dim.d_year, date_dim.d_moy
),
returns_agg AS (
    SELECT
        store.s_store_sk,
        date_dim.d_year,
        date_dim.d_moy,
        sum(store_returns.sr_net_loss) AS total_returns,
        sum(store_returns.sr_return_quantity) AS total_return_qty
    FROM store_returns
    JOIN store ON store_returns.sr_store_sk = store.s_store_sk
    JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY store.s_store_sk, date_dim.d_year, date_dim.d_moy
)
SELECT
    s_aggr.s_store_name,
    s_aggr.d_year,
    s_aggr.d_moy,
    s_aggr.total_sales,
    coalesce(r_aggr.total_returns, 0) AS total_returns,
    s_aggr.total_sales - coalesce(r_aggr.total_returns, 0) AS net_profit,
    case when s_aggr.sales_cnt > 0 then s_aggr.total_discount / s_aggr.sales_cnt else 0 end AS avg_discount_per_sale,
    coalesce(r_aggr.total_return_qty, 0) AS total_return_qty
FROM sales_agg AS s_aggr
LEFT JOIN returns_agg AS r_aggr
    ON s_aggr.s_store_sk = r_aggr.s_store_sk
   AND s_aggr.d_year = r_aggr.d_year
   AND s_aggr.d_moy = r_aggr.d_moy
ORDER BY s_aggr.s_store_name, s_aggr.d_year, s_aggr.d_moy
