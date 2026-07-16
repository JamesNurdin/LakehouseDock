WITH sales_detail AS (
  SELECT
    s.s_store_name,
    d.d_year,
    d.d_moy,
    cd.cd_gender,
    p.p_promo_name,
    ss.ss_net_profit,
    ss.ss_ext_sales_price,
    ss.ss_ext_discount_amt
  FROM store_sales ss
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  WHERE s.s_closed_date_sk IS NULL
    AND d.d_year = 2001
    AND p.p_discount_active = 'Y'
),

aggregated_sales AS (
  SELECT
    s_store_name,
    d_year,
    d_moy,
    cd_gender,
    p_promo_name,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(ss_ext_sales_price) AS total_sales,
    AVG(ss_ext_discount_amt) AS avg_discount,
    COUNT(*) AS transaction_count
  FROM sales_detail
  GROUP BY s_store_name, d_year, d_moy, cd_gender, p_promo_name
)

SELECT
  s_store_name,
  d_year,
  d_moy,
  cd_gender,
  p_promo_name,
  total_net_profit,
  total_sales,
  avg_discount,
  transaction_count,
  total_net_profit / transaction_count AS net_profit_per_transaction,
  RANK() OVER (PARTITION BY d_year, d_moy ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated_sales
ORDER BY d_year, d_moy, profit_rank, s_store_name
