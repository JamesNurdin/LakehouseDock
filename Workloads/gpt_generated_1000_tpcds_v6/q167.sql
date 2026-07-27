WITH sales_returns AS (
  SELECT
    c.c_customer_id,
    i.i_category,
    d_sales.d_year AS year,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
  FROM store_sales ss
  JOIN date_dim d_sales
    ON ss.ss_sold_date_sk = d_sales.d_date_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN date_dim d_return
    ON sr.sr_returned_date_sk = d_return.d_date_sk
  WHERE d_sales.d_year = 2001
    AND i.i_wholesale_cost > 0.5
    AND i.i_current_price < 20
    AND c.c_preferred_cust_flag = 'Y'
    AND cd.cd_gender = 'F'
    AND hd.hd_buy_potential = '5000-10000'
    AND p.p_discount_active = 'Y'
    AND (d_return.d_year = 2001 OR d_return.d_year IS NULL)
  GROUP BY ROLLUP (c.c_customer_id, i.i_category, d_sales.d_year)
)
SELECT
  c_customer_id,
  SUM(total_sales) AS cust_total_sales,
  SUM(total_returns) AS cust_total_returns,
  SUM(total_profit) AS cust_total_profit,
  SUM(num_transactions) AS cust_num_transactions
FROM sales_returns
WHERE i_category IS NULL
GROUP BY c_customer_id
HAVING SUM(total_sales) > 10000
ORDER BY cust_total_sales DESC
LIMIT 100
