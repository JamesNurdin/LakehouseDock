WITH sales_returns AS (
  SELECT
    s.s_store_id AS store_id,
    td.t_hour AS hour_of_day,
    SUM(cs.cs_ext_sales_price) AS store_sales,
    SUM(sr.sr_return_amt)        AS store_returns,
    SUM(cs.cs_net_profit)        AS store_profit,
    SUM(cs.cs_quantity)          AS total_qty
  FROM catalog_sales cs
  JOIN time_dim td               ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
  JOIN store_returns sr          ON sr.sr_item_sk = i.i_item_sk
  JOIN store s                   ON sr.sr_store_sk = s.s_store_sk
  JOIN web_page wp               ON wp.wp_customer_sk = c.c_customer_sk
  JOIN web_returns wr            ON wr.wr_item_sk = i.i_item_sk
  WHERE cs.cs_quantity > 1
    AND cs.cs_net_paid > 100
    AND i.i_current_price BETWEEN 10 AND 100
    AND hd.hd_dep_count >= 2
    AND s.s_state = 'CA'
    AND td.t_hour BETWEEN 9 AND 17
    AND p.p_discount_active = 'Y'
    AND wp.wp_type = 'product'
  GROUP BY s.s_store_id, td.t_hour
)
SELECT
  store_id,
  AVG(store_sales)   AS avg_hourly_sales,
  AVG(store_returns) AS avg_hourly_returns,
  AVG(store_profit)  AS avg_hourly_profit,
  SUM(total_qty)     AS total_quantity
FROM sales_returns
GROUP BY store_id
HAVING SUM(total_qty) > 100
ORDER BY avg_hourly_sales DESC
LIMIT 5
