WITH site_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        ws.ws_sold_time_sk
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
       AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT
    w.web_site_id,
    w.web_manager,
    REGEXP_EXTRACT(w.web_manager, '([A-Z][a-z]+) ([A-Z][a-z]+)', 1) AS manager_first_name,
    CONCAT(w.web_city, ', ', w.web_state) AS site_location,
    SUM(ss.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(ss.wr_return_amt, 0)) AS total_return_amount,
    COUNT(DISTINCT ss.ws_order_number) AS orders_with_sales,
    COUNT(DISTINCT ss.wr_return_quantity) AS total_return_qty,
    AVG(ss.ws_net_profit) AS avg_net_profit_per_order
FROM web_site w
JOIN site_sales ss ON w.web_site_sk = ss.ws_web_site_sk
WHERE 
    w.web_manager LIKE 'John%'
    AND REGEXP_LIKE(w.web_name, '^.*Online.*$')
    AND SUBSTRING(w.web_zip, 1, 1) = '9'
    AND ss.ws_sold_time_sk IN (
        SELECT t.t_time_sk
        FROM time_dim t
        WHERE t.t_hour BETWEEN 9 AND 17
          AND t.t_am_pm = 'PM'
    )
GROUP BY
    w.web_site_id,
    w.web_manager,
    REGEXP_EXTRACT(w.web_manager, '([A-Z][a-z]+) ([A-Z][a-z]+)', 1),
    CONCAT(w.web_city, ', ', w.web_state)
HAVING
    SUM(ss.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales)
ORDER BY total_net_profit DESC
LIMIT 100
