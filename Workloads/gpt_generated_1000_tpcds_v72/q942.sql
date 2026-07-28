WITH sales_city AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        concat(ca.ca_city, ', ', ca.ca_state) AS city_state,
        regexp_extract(ca.ca_address_id, '(\\d+)') AS address_digits,
        sum(ws.ws_net_paid_inc_tax) AS total_net_paid,
        sum(ws.ws_net_profit) AS total_profit,
        count(DISTINCT ws.ws_order_number) AS order_cnt,
        avg(ws.ws_ext_discount_amt) AS avg_discount,
        CASE
            WHEN sum(ws.ws_net_profit) > 5000 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM web_sales ws
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE (regexp_like(ca.ca_city, '^Oak') OR ca.ca_city LIKE '%Valley%')
      AND ws.ws_net_paid_inc_tax > 0
    GROUP BY ca.ca_city, ca.ca_state, ca.ca_address_id
)
SELECT *
FROM sales_city
ORDER BY total_net_paid DESC
LIMIT 100
