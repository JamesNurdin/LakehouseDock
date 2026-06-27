WITH
  sales_agg AS (
    SELECT
      ss.ss_store_sk,
      ss.ss_sold_date_sk,
      ss.ss_promo_sk,
      SUM(ss.ss_net_paid) AS total_sales_net_paid,
      SUM(ss.ss_net_profit) AS total_sales_net_profit
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk
  ),
  sales_month AS (
    SELECT
      sagg.ss_store_sk,
      d.d_year,
      date_format(d.d_date, '%Y-%m') AS year_month,
      p.p_promo_name,
      sagg.total_sales_net_paid,
      sagg.total_sales_net_profit
    FROM sales_agg sagg
    JOIN date_dim d
      ON sagg.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN promotion p
      ON sagg.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
  ),
  returns_agg AS (
    SELECT
      sr.sr_store_sk,
      sr.sr_returned_date_sk,
      SUM(sr.sr_net_loss) AS total_returns_net_loss
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_returned_date_sk
  ),
  returns_month AS (
    SELECT
      ragg.sr_store_sk,
      d.d_year,
      date_format(d.d_date, '%Y-%m') AS year_month,
      ragg.total_returns_net_loss
    FROM returns_agg ragg
    JOIN date_dim d
      ON ragg.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
  ),
  store_info AS (
    SELECT
      s.s_store_sk,
      s.s_store_name,
      s.s_city,
      s.s_state,
      s.s_tax_percentage
    FROM store s
  ),
  sales_returns_combined AS (
    SELECT
      COALESCE(sm.ss_store_sk, rm.sr_store_sk) AS store_sk,
      COALESCE(sm.year_month, rm.year_month) AS year_month,
      sm.p_promo_name,
      sm.total_sales_net_paid,
      sm.total_sales_net_profit,
      rm.total_returns_net_loss
    FROM sales_month sm
    FULL OUTER JOIN returns_month rm
      ON sm.ss_store_sk = rm.sr_store_sk
     AND sm.year_month = rm.year_month
  )
SELECT
  si.s_store_name,
  si.s_city,
  si.s_state,
  src.year_month,
  src.p_promo_name,
  COALESCE(src.total_sales_net_paid, 0) AS total_sales_net_paid,
  COALESCE(src.total_sales_net_profit, 0) AS total_sales_net_profit,
  COALESCE(src.total_returns_net_loss, 0) AS total_returns_net_loss,
  COALESCE(src.total_sales_net_profit, 0) - COALESCE(src.total_returns_net_loss, 0) AS net_effect
FROM store_info si
JOIN sales_returns_combined src
  ON si.s_store_sk = src.store_sk
ORDER BY si.s_store_name, src.year_month
