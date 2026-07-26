WITH daily_manufacturer_sales AS (
    SELECT w.web_site_id,
           ca_bill.ca_state AS bill_state,
           i.i_manufact AS manufacturer_id,
           ws.ws_sold_date_sk AS sold_date_key,
           SUM(ws.ws_net_profit) AS daily_net_profit,
           SUM(ws.ws_ext_sales_price) AS daily_sales
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    WHERE w.web_name LIKE 'Site%'
    GROUP BY w.web_site_id, ca_bill.ca_state, i.i_manufact, ws.ws_sold_date_sk
)
SELECT web_site_id,
       bill_state,
       manufacturer_id,
       sold_date_key,
       daily_net_profit,
       daily_sales,
       CASE WHEN daily_sales = 0 THEN 0 ELSE daily_net_profit / daily_sales END AS profit_margin,
       MAX(daily_net_profit) OVER (PARTITION BY manufacturer_id) AS max_daily_profit,
       RANK() OVER (PARTITION BY bill_state ORDER BY daily_net_profit DESC) AS state_profit_rank
FROM daily_manufacturer_sales
WHERE daily_sales BETWEEN 500 AND 5000
ORDER BY bill_state, daily_sales DESC
