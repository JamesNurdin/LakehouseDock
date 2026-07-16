SELECT
  s.s_store_name AS store_name,
  d.d_year,
  d.d_month_seq,
  sum(ss.ss_ext_sales_price) AS total_sales,
  sum(ss.ss_net_profit) AS total_profit,
  sum(ss.ss_quantity) AS total_quantity,
  avg(ss.ss_sales_price) AS avg_price
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Sports'
  AND p.p_discount_active = 'Y'
  AND cd.cd_gender = 'M'
  AND hd.hd_income_band_sk BETWEEN 5 AND 10
GROUP BY s.s_store_name, d.d_year, d.d_month_seq
ORDER BY total_profit DESC
LIMIT 10
