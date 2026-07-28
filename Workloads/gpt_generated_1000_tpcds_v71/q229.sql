WITH joined AS (
  SELECT
    ca.ca_state,
    p.p_channel_email,
    i.i_category,
    cs.cs_ext_sales_price AS cs_sales,
    ss.ss_ext_sales_price AS ss_sales,
    cs.cs_net_profit AS cs_profit,
    ss.ss_net_profit AS ss_profit,
    sr.sr_refunded_cash AS sr_refund,
    sr.sr_net_loss AS sr_loss
  FROM store_sales ss
  JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
  JOIN catalog_sales cs
    ON cs.cs_sold_time_sk = t.t_time_sk
   AND cs.cs_item_sk = i.i_item_sk
   AND cs.cs_promo_sk = p.p_promo_sk
   AND cs.cs_bill_addr_sk = ca.ca_address_sk
  WHERE
    p.p_channel_email = 'Y'
    AND i.i_size IN ('medium', 'small')
    AND t.t_hour BETWEEN 9 AND 17
    AND ca.ca_state = 'CA'
),
sales_agg AS (
  SELECT
    ca_state,
    p_channel_email,
    i_category,
    SUM(cs_sales) AS sum_catalog_sales,
    SUM(ss_sales) AS sum_store_sales,
    SUM(cs_profit) AS sum_catalog_profit,
    SUM(ss_profit) AS sum_store_profit,
    SUM(sr_refund) AS sum_refund,
    SUM(sr_loss) AS sum_return_loss
  FROM joined
  GROUP BY ROLLUP (ca_state, p_channel_email, i_category)
)
SELECT
  ca_state,
  p_channel_email,
  i_category,
  sum_catalog_sales,
  sum_store_sales,
  (sum_catalog_sales + sum_store_sales) AS total_sales,
  (sum_catalog_profit + sum_store_profit) AS total_profit,
  CASE
    WHEN (sum_catalog_profit + sum_store_profit) > 50000 THEN 'High'
    ELSE 'Low'
  END AS profit_level,
  sum_refund,
  sum_return_loss
FROM sales_agg
WHERE
  (sum_catalog_sales + sum_store_sales) > 100000
  AND (sum_catalog_profit + sum_store_profit) IS NOT NULL
  AND sum_refund < 50000
ORDER BY
  ca_state NULLS LAST,
  p_channel_email NULLS LAST,
  i_category NULLS LAST
