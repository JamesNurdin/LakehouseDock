SELECT
  (d.d_year * 100 + d.d_month_seq) AS year_month,
  hd.hd_income_band_sk,
  p.p_channel_email,
  SUM(cs.cs_net_profit) AS profit,
  SUM(SUM(cs.cs_net_profit)) OVER (PARTITION BY (d.d_year * 100 + d.d_month_seq), hd.hd_income_band_sk) AS total_profit_month_income,
  SUM(cs.cs_net_profit) / SUM(SUM(cs.cs_net_profit)) OVER (PARTITION BY (d.d_year * 100 + d.d_month_seq), hd.hd_income_band_sk) AS profit_share
FROM catalog_sales cs
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN promotion p
  ON cs.cs_promo_sk = p.p_promo_sk
WHERE d.d_date >= DATE '2022-01-01'
  AND d.d_date < DATE '2023-01-01'
  AND i.i_category = 'Electronics'
GROUP BY (d.d_year * 100 + d.d_month_seq), hd.hd_income_band_sk, p.p_channel_email
ORDER BY year_month, hd.hd_income_band_sk, p.p_channel_email
