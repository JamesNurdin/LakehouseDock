WITH sales_returns AS (
  SELECT
    ss.ss_sold_date_sk AS sold_date_sk,
    ss.ss_ticket_number AS ticket_number,
    ss.ss_item_sk AS item_sk,
    ss.ss_quantity AS sales_quantity,
    ss.ss_ext_discount_amt AS sales_discount_amount,
    ss.ss_net_profit AS sales_net_profit,
    ss.ss_customer_sk AS sales_customer_sk,
    ss.ss_promo_sk AS promo_sk,
    sr.sr_return_quantity AS return_quantity,
    sr.sr_net_loss AS return_net_loss
  FROM store_sales ss
  LEFT JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
)
SELECT
  d.d_year,
  month(d.d_date) AS month,
  p.p_promo_name,
  sum(sales_quantity) AS total_quantity_sold,
  sum(coalesce(return_quantity, 0)) AS total_quantity_returned,
  sum(sales_quantity) - sum(coalesce(return_quantity, 0)) AS net_quantity_sold,
  sum(sales_net_profit) AS total_sales_net_profit,
  sum(coalesce(return_net_loss, 0)) AS total_returns_net_loss,
  sum(sales_net_profit) + sum(coalesce(return_net_loss, 0)) AS net_profit_after_returns,
  sum(sales_discount_amount) AS total_discount_amount,
  avg(sales_discount_amount) AS avg_discount_per_sale,
  count(distinct sales_customer_sk) AS distinct_customers
FROM sales_returns sr
JOIN date_dim d
  ON sr.sold_date_sk = d.d_date_sk
JOIN promotion p
  ON sr.promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND p.p_discount_active = 'Y'
GROUP BY d.d_year, month(d.d_date), p.p_promo_name
ORDER BY d.d_year, month(d.d_date), p.p_promo_name
