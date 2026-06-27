WITH sales_agg AS (
   SELECT
      store.s_store_id,
      store.s_store_name,
      date_dim.d_year,
      date_dim.d_moy,
      promotion.p_promo_id,
      promotion.p_channel_email,
      SUM(store_sales.ss_net_paid) AS total_net_paid,
      SUM(store_sales.ss_net_profit) AS total_net_profit
   FROM store_sales
   JOIN date_dim   ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
   JOIN store      ON store_sales.ss_store_sk   = store.s_store_sk
   JOIN promotion  ON store_sales.ss_promo_sk  = promotion.p_promo_sk
   WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
   GROUP BY
      store.s_store_id,
      store.s_store_name,
      date_dim.d_year,
      date_dim.d_moy,
      promotion.p_promo_id,
      promotion.p_channel_email
),
returns_agg AS (
   SELECT
      store.s_store_id,
      date_dim.d_year,
      date_dim.d_moy,
      SUM(store_returns.sr_net_loss) AS total_return_loss
   FROM store_returns
   JOIN date_dim ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
   JOIN store    ON store_returns.sr_store_sk       = store.s_store_sk
   WHERE date_dim.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
   GROUP BY
      store.s_store_id,
      date_dim.d_year,
      date_dim.d_moy
)
SELECT
   sales_agg.s_store_id,
   sales_agg.s_store_name,
   sales_agg.d_year,
   sales_agg.d_moy,
   sales_agg.p_channel_email,
   sales_agg.total_net_paid,
   sales_agg.total_net_profit,
   COALESCE(returns_agg.total_return_loss, 0) AS total_return_loss,
   sales_agg.total_net_profit - COALESCE(returns_agg.total_return_loss, 0) AS net_profit_after_returns
FROM sales_agg
LEFT JOIN returns_agg
   ON sales_agg.s_store_id = returns_agg.s_store_id
  AND sales_agg.d_year    = returns_agg.d_year
  AND sales_agg.d_moy     = returns_agg.d_moy
ORDER BY
   sales_agg.s_store_id,
   sales_agg.d_year,
   sales_agg.d_moy
