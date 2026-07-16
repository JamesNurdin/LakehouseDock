WITH sold_date AS (
    SELECT ws.ws_sold_date_sk,
           ws.ws_sold_time_sk,
           ws.ws_web_site_sk,
           ws.ws_bill_addr_sk,
           ws.ws_net_profit,
           ws.ws_quantity,
           ws.ws_ext_discount_amt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
),
billing_us AS (
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_country = 'United States'
),
evening_time AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_hour >= 18
),
aggregated AS (
    SELECT ws_site.web_name,
           cp.cp_department,
           SUM(ws.ws_net_profit) AS total_net_profit,
           SUM(ws.ws_quantity) AS total_quantity,
           AVG(ws.ws_ext_discount_amt) AS avg_discount
    FROM sold_date ws
    JOIN evening_time td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN billing_us ba ON ws.ws_bill_addr_sk = ba.ca_address_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = ws.ws_sold_date_sk
    GROUP BY ws_site.web_name, cp.cp_department
    HAVING SUM(ws.ws_net_profit) > 0
)
SELECT a.web_name,
       a.cp_department,
       a.total_net_profit,
       a.total_quantity,
       a.avg_discount,
       RANK() OVER (PARTITION BY a.web_name ORDER BY a.total_net_profit DESC) AS dept_rank
FROM aggregated a
ORDER BY a.web_name, dept_rank
LIMIT 100
