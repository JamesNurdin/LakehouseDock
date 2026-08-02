(SELECT d_sales.d_year AS sale_year,
        ca_store.ca_state AS store_state,
        CASE WHEN (SUM(s.ss_net_profit) + SUM(w.ws_net_profit) - SUM(cr.cr_net_loss)) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS net_profit_flag
 FROM store_sales s
 JOIN date_dim d_sales ON s.ss_sold_date_sk = d_sales.d_date_sk
 JOIN time_dim t_sales ON s.ss_sold_time_sk = t_sales.t_time_sk
 JOIN promotion p_sales ON s.ss_promo_sk = p_sales.p_promo_sk
 JOIN customer_address ca_store ON s.ss_addr_sk = ca_store.ca_address_sk
 JOIN web_sales w ON w.ws_sold_date_sk = d_sales.d_date_sk
 JOIN time_dim t_ws ON w.ws_sold_time_sk = t_ws.t_time_sk
 JOIN promotion p_ws ON w.ws_promo_sk = p_ws.p_promo_sk
 JOIN customer_address ca_bill ON w.ws_bill_addr_sk = ca_bill.ca_address_sk
 JOIN customer_address ca_ship ON w.ws_ship_addr_sk = ca_ship.ca_address_sk
 JOIN catalog_returns cr ON cr.cr_returned_date_sk = d_sales.d_date_sk
 JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
 JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
 JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
 JOIN promotion p_start_ret ON p_start_ret.p_start_date_sk = d_sales.d_date_sk
 JOIN promotion p_end_ret ON p_end_ret.p_end_date_sk = d_sales.d_date_sk
 GROUP BY d_sales.d_year, ca_store.ca_state
 HAVING (SUM(s.ss_net_profit) + SUM(w.ws_net_profit) - SUM(cr.cr_net_loss)) > 1000
)
INTERSECT
(SELECT d_ws.d_year AS sale_year,
        ca_store2.ca_state AS store_state,
        CASE WHEN (SUM(s2.ss_net_profit) + SUM(w2.ws_net_profit) - SUM(cr2.cr_net_loss)) > 0 THEN 'POSITIVE' ELSE 'NEGATIVE' END AS net_profit_flag
 FROM web_sales w2
 JOIN date_dim d_ws ON w2.ws_sold_date_sk = d_ws.d_date_sk
 JOIN time_dim t_ws2 ON w2.ws_sold_time_sk = t_ws2.t_time_sk
 JOIN promotion p_ws2 ON w2.ws_promo_sk = p_ws2.p_promo_sk
 JOIN customer_address ca_store2 ON w2.ws_bill_addr_sk = ca_store2.ca_address_sk
 JOIN customer_address ca_ship2 ON w2.ws_ship_addr_sk = ca_ship2.ca_address_sk
 JOIN store_sales s2 ON s2.ss_item_sk = w2.ws_item_sk AND s2.ss_sold_date_sk = d_ws.d_date_sk
 JOIN time_dim t_sales2 ON s2.ss_sold_time_sk = t_sales2.t_time_sk
 JOIN promotion p_sales2 ON s2.ss_promo_sk = p_sales2.p_promo_sk
 JOIN customer_address ca_addr2 ON s2.ss_addr_sk = ca_addr2.ca_address_sk
 JOIN catalog_returns cr2 ON cr2.cr_returned_date_sk = d_ws.d_date_sk
 JOIN time_dim t_ret2 ON cr2.cr_returned_time_sk = t_ret2.t_time_sk
 JOIN customer_address ca_refund2 ON cr2.cr_refunded_addr_sk = ca_refund2.ca_address_sk
 JOIN customer_address ca_returning2 ON cr2.cr_returning_addr_sk = ca_returning2.ca_address_sk
 JOIN promotion p_start_ret2 ON p_start_ret2.p_start_date_sk = d_ws.d_date_sk
 JOIN promotion p_end_ret2 ON p_end_ret2.p_end_date_sk = d_ws.d_date_sk
 GROUP BY d_ws.d_year, ca_store2.ca_state
 HAVING (SUM(s2.ss_net_profit) + SUM(w2.ws_net_profit) - SUM(cr2.cr_net_loss)) > 1000
)
LIMIT 100
