WITH city_item_rank AS (
    SELECT ca_bill.ca_city AS city,
           w.web_site_id,
           i.i_product_name AS product_name,
           SUM(ws.ws_net_paid) AS total_net_paid,
           SUM(ws.ws_net_profit) AS total_profit,
           CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable'
                WHEN SUM(ws.ws_net_profit) = 0 THEN 'Break-even'
                ELSE 'Loss' END AS profitability,
           ROW_NUMBER() OVER (PARTITION BY ca_bill.ca_city ORDER BY SUM(ws.ws_net_paid) DESC) AS rn
    FROM web_sales ws
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY ca_bill.ca_city, w.web_site_id, i.i_product_name
)
SELECT city,
       web_site_id,
       product_name,
       total_net_paid,
       total_profit,
       profitability
FROM city_item_rank
WHERE rn <= 3
ORDER BY city, rn
