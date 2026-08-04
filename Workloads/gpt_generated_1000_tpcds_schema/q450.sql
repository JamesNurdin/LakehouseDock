WITH store_data AS (
  SELECT
    s.s_state AS dimension,
    ib.ib_income_band_sk AS income_band,
    p.p_promo_name AS promo_name,
    pl.profit_level,
    SUM(COALESCE(ss.ss_ext_sales_price, 0) - COALESCE(sr.sr_refunded_cash, 0)) AS total_sales,
    COUNT(DISTINCT COALESCE(ss.ss_ticket_number, sr.sr_ticket_number)) AS txn_count
  FROM store_sales ss
  FULL OUTER JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
  LEFT JOIN store s
    ON COALESCE(ss.ss_store_sk, sr.sr_store_sk) = s.s_store_sk
  LEFT JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN household_demographics hd
    ON COALESCE(ss.ss_hdemo_sk, sr.sr_hdemo_sk) = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  CROSS JOIN LATERAL (
    SELECT CASE
             WHEN COALESCE(ss.ss_net_profit, sr.sr_net_loss) > 1000 THEN 'High'
             WHEN COALESCE(ss.ss_net_profit, sr.sr_net_loss) > 0 THEN 'Medium'
             ELSE 'Low'
           END AS profit_level
  ) pl
  WHERE s.s_state = 'CA'
  GROUP BY CUBE(s.s_state, ib.ib_income_band_sk, p.p_promo_name, pl.profit_level)
),
web_data AS (
  SELECT
    c.c_preferred_cust_flag AS dimension,
    ib.ib_income_band_sk AS income_band,
    p.p_promo_name AS promo_name,
    pl.profit_level,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS txn_count
  FROM web_sales ws
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  CROSS JOIN LATERAL (
    SELECT CASE
             WHEN ws.ws_net_profit > 1000 THEN 'High'
             WHEN ws.ws_net_profit > 0 THEN 'Medium'
             ELSE 'Low'
           END AS profit_level
  ) pl
  WHERE ws.ws_net_paid > 0
  GROUP BY CUBE(c.c_preferred_cust_flag, ib.ib_income_band_sk, p.p_promo_name, pl.profit_level)
)
SELECT *
FROM store_data
UNION ALL
SELECT *
FROM web_data
ORDER BY total_sales DESC
LIMIT 100
