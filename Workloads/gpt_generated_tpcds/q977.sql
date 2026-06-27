WITH sales_agg AS (
  SELECT
    store.s_store_sk,
    store.s_store_name,
    dsales.d_year,
    dsales.d_moy,
    SUM(store_sales.ss_ext_sales_price) AS total_sales_amount,
    SUM(store_sales.ss_ext_tax) AS total_sales_tax,
    SUM(store_sales.ss_net_profit) AS total_sales_profit,
    SUM(store_sales.ss_quantity) AS total_quantity_sold
  FROM store_sales
  JOIN store ON store_sales.ss_store_sk = store.s_store_sk
  JOIN date_dim dsales ON store_sales.ss_sold_date_sk = dsales.d_date_sk
  WHERE dsales.d_year BETWEEN 2001 AND 2002
  GROUP BY store.s_store_sk, store.s_store_name, dsales.d_year, dsales.d_moy
),
returns_agg AS (
  SELECT
    store.s_store_sk,
    store.s_store_name,
    dreturns.d_year,
    dreturns.d_moy,
    SUM(store_returns.sr_return_amt) AS total_return_amount,
    SUM(store_returns.sr_return_tax) AS total_return_tax,
    SUM(store_returns.sr_net_loss) AS total_return_loss,
    SUM(store_returns.sr_return_quantity) AS total_quantity_returned
  FROM store_returns
  JOIN store ON store_returns.sr_store_sk = store.s_store_sk
  JOIN date_dim dreturns ON store_returns.sr_returned_date_sk = dreturns.d_date_sk
  WHERE dreturns.d_year BETWEEN 2001 AND 2002
  GROUP BY store.s_store_sk, store.s_store_name, dreturns.d_year, dreturns.d_moy
)
SELECT
  s.s_store_name,
  s.d_year,
  s.d_moy,
  s.total_sales_amount,
  s.total_sales_tax,
  s.total_sales_profit,
  COALESCE(r.total_return_amount, 0) AS total_return_amount,
  COALESCE(r.total_return_tax, 0) AS total_return_tax,
  COALESCE(r.total_return_loss, 0) AS total_return_loss,
  (s.total_sales_profit - COALESCE(r.total_return_loss, 0)) AS net_profit_after_returns,
  CASE
    WHEN s.total_quantity_sold > 0 THEN (COALESCE(r.total_quantity_returned, 0) * 1.0) / s.total_quantity_sold
    ELSE 0
  END AS return_rate,
  SUM(s.total_sales_profit - COALESCE(r.total_return_loss, 0)) OVER (
    PARTITION BY s.s_store_name
    ORDER BY s.d_year, s.d_moy
    ROWS UNBOUNDED PRECEDING
  ) AS cumulative_net_profit
FROM sales_agg s
LEFT JOIN returns_agg r
  ON s.s_store_sk = r.s_store_sk
  AND s.d_year = r.d_year
  AND s.d_moy = r.d_moy
ORDER BY net_profit_after_returns DESC
LIMIT 100
