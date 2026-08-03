WITH sales_cte AS (
  SELECT
    cs.cs_sold_date_sk,
    d.d_year,
    d.d_date,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    w.w_state,
    p.p_channel_dmail,
    p.p_promo_id,
    c.c_email_address,
    hd.hd_income_band_sk,
    ib.ib_upper_bound,
    regexp_extract(p.p_promo_id, '^(..)', 1) AS promo_prefix,
    CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
  FROM
    tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE
    d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    AND regexp_like(p.p_channel_dmail, '^Y')
    AND c.c_email_address LIKE '%@example.com'
),
agg_cte AS (
  SELECT
    d_year,
    w_state,
    p_channel_dmail,
    SUM(cs_net_paid) AS total_paid,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS order_cnt
  FROM sales_cte
  GROUP BY CUBE (d_year, w_state, p_channel_dmail)
  HAVING SUM(cs_net_paid) > (SELECT AVG(ib_upper_bound) FROM tpcds.income_band)
)
SELECT
  d_year,
  w_state,
  p_channel_dmail,
  total_paid,
  total_profit,
  order_cnt,
  SUM(total_profit) OVER (PARTITION BY d_year ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_profit_year,
  LAG(total_profit) OVER (PARTITION BY d_year ORDER BY total_profit) AS prior_profit,
  SUBSTRING(w_state FROM 1 FOR 1) AS state_initial,
  CONCAT(p_channel_dmail, '-', CASE WHEN total_profit > 0 THEN 'POS' ELSE 'NEG' END) AS channel_profit_flag
FROM agg_cte
ORDER BY total_profit DESC
LIMIT 100
