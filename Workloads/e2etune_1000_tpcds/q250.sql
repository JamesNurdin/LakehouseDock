SELECT
    p.p_promo_name,
    w.w_city,
    SUM(ss.ss_net_profit) AS total_sales_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss) AS net_contribution,
    COUNT(DISTINCT ss.ss_customer_sk) AS num_customers_with_sales,
    COUNT(DISTINCT cr.cr_returning_customer_sk) AS num_customers_with_returns
FROM store_sales ss
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN catalog_returns cr
    ON c.c_customer_sk = cr.cr_returning_customer_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE ss.ss_sold_date_sk BETWEEN 2450815 AND 2451949
  AND ss.ss_quantity > 5
  AND cr.cr_return_quantity > 20
  AND cr.cr_return_ship_cost > 300
  AND p.p_response_target > 500
GROUP BY p.p_promo_name, w.w_city
HAVING SUM(cr.cr_net_loss) > 1000
ORDER BY net_contribution DESC
LIMIT 50
