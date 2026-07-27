WITH income_avg AS (
  SELECT hd.hd_demo_sk,
         (ib.ib_lower_bound + ib.ib_upper_bound) / 2.0 AS income_mid
  FROM household_demographics hd
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_with_promo AS (
  SELECT d.d_year AS year,
         'WITH_PROMO' AS promo_flag,
         SUM(ws.ws_ext_sales_price) AS total_sales,
         AVG(ia.income_mid) AS avg_income,
         CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
         CASE WHEN AVG(ia.income_mid) > (SELECT AVG(income_mid) FROM income_avg) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS income_relative_flag
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_avg ia
    ON hd.hd_demo_sk = ia.hd_demo_sk
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  GROUP BY d.d_year
),
sales_without_promo AS (
  SELECT d.d_year AS year,
         'WITHOUT_PROMO' AS promo_flag,
         SUM(ws.ws_ext_sales_price) AS total_sales,
         AVG(ia.income_mid) AS avg_income,
         CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
         CASE WHEN AVG(ia.income_mid) > (SELECT AVG(income_mid) FROM income_avg) THEN 'ABOVE_AVG' ELSE 'BELOW_AVG' END AS income_relative_flag
  FROM web_sales ws
  JOIN date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_avg ia
    ON hd.hd_demo_sk = ia.hd_demo_sk
  LEFT JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  WHERE p.p_promo_sk IS NULL
  GROUP BY d.d_year
)
SELECT year,
       promo_flag,
       total_sales,
       avg_income,
       profit_flag,
       income_relative_flag
FROM sales_with_promo
UNION ALL
SELECT year,
       promo_flag,
       total_sales,
       avg_income,
       profit_flag,
       income_relative_flag
FROM sales_without_promo
ORDER BY year, promo_flag
