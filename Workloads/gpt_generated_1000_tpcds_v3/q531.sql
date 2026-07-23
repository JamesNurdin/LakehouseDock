WITH sales_returns AS (
  SELECT DISTINCT
    ss.ss_sold_date_sk,
    ss.ss_sold_time_sk,
    ss.ss_item_sk,
    ss.ss_customer_sk,
    ss.ss_store_sk,
    ss.ss_ticket_number,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_return_tax,
    sr.sr_net_loss,
    t_sale.t_hour   AS sale_hour,
    t_sale.t_minute AS sale_minute,
    t_sale.t_second AS sale_second,
    t_return.t_hour   AS return_hour,
    t_return.t_minute AS return_minute,
    t_return.t_second AS return_second,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag
  FROM store_sales ss
  JOIN store_returns sr
    ON ss.ss_item_sk = sr.sr_item_sk
   AND ss.ss_ticket_number = sr.sr_ticket_number
  JOIN time_dim t_sale
    ON ss.ss_sold_time_sk = t_sale.t_time_sk
  JOIN time_dim t_return
    ON sr.sr_return_time_sk = t_return.t_time_sk
  JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
   AND sr.sr_customer_sk = c.c_customer_sk
  WHERE ss.ss_ext_sales_price > 1000
    AND sr.sr_return_tax BETWEEN 2 AND 10
    AND c.c_preferred_cust_flag = 'Y'
    AND t_sale.t_hour BETWEEN 9 AND 17
    AND t_return.t_hour BETWEEN 10 AND 18
    AND EXISTS (
      SELECT 1
      FROM catalog_returns cr
      WHERE cr.cr_returned_time_sk = t_return.t_time_sk
        AND cr.cr_return_amount > 200
    )
)
SELECT
  sr.c_customer_sk,
  sr.c_first_name,
  sr.c_last_name,
  sr.ss_ticket_number,
  sr.ss_ext_sales_price,
  sr.ss_net_profit,
  sr.sr_return_amt,
  sr.sr_return_tax,
  sr.sale_hour,
  sr.sale_minute,
  sr.sale_second,
  sr.return_hour,
  sr.return_minute,
  sr.return_second,
  sr.ss_store_sk,
  DENSE_RANK() OVER (PARTITION BY sr.ss_store_sk ORDER BY sr.ss_net_profit DESC) AS store_profit_rank
FROM sales_returns sr
WHERE sr.sr_return_amt IS NOT NULL
ORDER BY store_profit_rank, sr.ss_net_profit DESC
LIMIT 100
