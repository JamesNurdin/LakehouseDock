WITH category_promo_sales AS (
  SELECT
    i.i_category AS category,
    p.p_promo_name AS promotion,
    hd.hd_income_band_sk AS income_band,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_cnt
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE p.p_discount_active = 'Y'
    AND i.i_category IN ('Books', 'Electronics', 'Clothing')
    AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
  GROUP BY i.i_category, p.p_promo_name, hd.hd_income_band_sk
)
SELECT
  category,
  promotion,
  income_band,
  total_sales,
  total_profit,
  avg_discount,
  transaction_cnt,
  RANK() OVER (PARTITION BY category ORDER BY total_profit DESC) AS profit_rank
FROM category_promo_sales
WHERE total_sales > 10000
ORDER BY category, profit_rank
