SELECT
    store.s_store_name,
    sd.d_year,
    sd.d_month_seq,
    SUM(ss.ss_net_profit) AS total_net_profit,
    SUM(CASE WHEN promotion.p_channel_email = 'Y' THEN ss.ss_net_profit ELSE 0 END) AS email_net_profit,
    AVG(household_demographics.hd_vehicle_count) AS avg_vehicle_count,
    AVG(ss.ss_quantity) AS avg_quantity,
    COUNT(*) AS total_transactions
FROM store_sales AS ss
JOIN date_dim AS sd
  ON ss.ss_sold_date_sk = sd.d_date_sk
JOIN store
  ON ss.ss_store_sk = store.s_store_sk
JOIN promotion
  ON ss.ss_promo_sk = promotion.p_promo_sk
JOIN household_demographics
  ON ss.ss_hdemo_sk = household_demographics.hd_demo_sk
WHERE sd.d_date >= DATE '2001-01-01'
  AND sd.d_date <= DATE '2001-12-31'
GROUP BY store.s_store_name, sd.d_year, sd.d_month_seq
ORDER BY total_net_profit DESC
LIMIT 10
