SELECT
    p.p_promo_name,
    t.t_hour,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_transactions
FROM store_sales ss
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
    ON cs.cs_promo_sk = p.p_promo_sk
    AND cs.cs_sold_time_sk = t.t_time_sk
    AND cs.cs_ship_customer_sk = c.c_customer_sk
WHERE ca.ca_state = 'CA'
  AND cs.cs_ext_sales_price > 1000
  AND t.t_hour BETWEEN 9 AND 21
GROUP BY p.p_promo_name, t.t_hour
HAVING SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) > 5000
ORDER BY total_net_profit DESC
LIMIT 100
