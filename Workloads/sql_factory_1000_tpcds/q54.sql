SELECT w.web_site_id,
       ca_bill.ca_state AS bill_state,
       SUM(ws.ws_net_profit) AS total_net_profit,
       COUNT(DISTINCT i.i_item_id) AS distinct_items_sold,
       CASE WHEN SUM(ws.ws_net_profit) > 1000000 THEN 'High'
            WHEN SUM(ws.ws_net_profit) > 500000 THEN 'Medium'
            ELSE 'Low' END AS profit_tier,
       RANK() OVER (PARTITION BY w.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS state_rank
FROM web_sales ws
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
GROUP BY w.web_site_id, ca_bill.ca_state
HAVING SUM(ws.ws_net_profit) > 0
ORDER BY w.web_site_id, state_rank
