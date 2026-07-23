SELECT p.p_promo_name,
       cd_current.cd_gender,
       cd_current.cd_credit_rating,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       SUM(ws.ws_quantity) AS total_quantity,
       AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
       MIN(ws.ws_net_profit) AS min_net_profit,
       MAX(ws.ws_net_profit) AS max_net_profit
FROM web_sales ws
INNER JOIN customer c_bill
    ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
INNER JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
INNER JOIN customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
INNER JOIN customer_demographics cd_current
    ON c_bill.c_current_cdemo_sk = cd_current.cd_demo_sk
WHERE p.p_end_date_sk BETWEEN 2450400 AND 2450500
  AND p.p_channel_dmail = 'Y'
  AND p.p_channel_radio = 'N'
  AND ws.ws_wholesale_cost > 10.00
  AND ws.ws_ext_wholesale_cost > 2000.00
  AND cd_bill.cd_credit_rating = 'High Risk'
  AND cd_bill.cd_dep_count >= 2
  AND c_bill.c_birth_year BETWEEN 1970 AND 1985
  AND ws.ws_quantity > 1
  AND ws.ws_wholesale_cost > (SELECT AVG(ws2.ws_wholesale_cost)
                               FROM web_sales ws2
                               WHERE ws2.ws_promo_sk = ws.ws_promo_sk)
GROUP BY p.p_promo_name,
         cd_current.cd_gender,
         cd_current.cd_credit_rating
ORDER BY total_sales DESC
LIMIT 100
