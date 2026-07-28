WITH inv_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    GROUP BY inv_date_sk
),
sub_a AS (
    SELECT d.d_year,
           ca.ca_state,
           SUM(cs.cs_net_paid)         AS cs_sales,
           SUM(ss.ss_net_paid)         AS ss_sales,
           SUM(ws.ws_net_paid)         AS ws_sales,
           SUM(wr.wr_return_amt)       AS returns,
           SUM(ia.total_qty_on_hand)   AS inventory_qty,
           COUNT(DISTINCT cs.cs_order_number) AS cs_orders,
           COUNT(DISTINCT ss.ss_ticket_number) AS ss_tickets,
           COUNT(DISTINCT ws.ws_order_number) AS ws_orders,
           COUNT(DISTINCT wr.wr_order_number) AS wr_orders
    FROM catalog_sales cs
    JOIN date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss    ON ss.ss_sold_date_sk = d.d_date_sk
                              AND ss.ss_customer_sk = c.c_customer_sk
                              AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws      ON ws.ws_sold_date_sk = d.d_date_sk
                              AND ws.ws_bill_customer_sk = c.c_customer_sk
                              AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr   ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r          ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we       ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inv_agg ia        ON ia.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND c.c_birth_country = 'USA'
      AND r.r_reason_desc = 'Lost my job'
      AND t.t_hour BETWEEN 8 AND 12
    GROUP BY d.d_year, ca.ca_state
),
sub_b AS (
    SELECT d.d_year,
           ca.ca_state,
           SUM(cs.cs_net_paid)         AS cs_sales,
           SUM(ss.ss_net_paid)         AS ss_sales,
           SUM(ws.ws_net_paid)         AS ws_sales,
           SUM(wr.wr_return_amt)       AS returns,
           SUM(ia.total_qty_on_hand)   AS inventory_qty,
           COUNT(DISTINCT cs.cs_order_number) AS cs_orders,
           COUNT(DISTINCT ss.ss_ticket_number) AS ss_tickets,
           COUNT(DISTINCT ws.ws_order_number) AS ws_orders,
           COUNT(DISTINCT wr.wr_order_number) AS wr_orders
    FROM catalog_sales cs
    JOIN date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss    ON ss.ss_sold_date_sk = d.d_date_sk
                              AND ss.ss_customer_sk = c.c_customer_sk
                              AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_sales ws      ON ws.ws_sold_date_sk = d.d_date_sk
                              AND ws.ws_bill_customer_sk = c.c_customer_sk
                              AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_returns wr   ON wr.wr_order_number = ws.ws_order_number
    JOIN reason r          ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_page wp       ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we       ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inv_agg ia        ON ia.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND c.c_birth_country = 'CAN'
      AND r.r_reason_desc = 'Found a better price in a store'
      AND t.t_hour BETWEEN 13 AND 17
    GROUP BY d.d_year, ca.ca_state
),
unioned AS (
    SELECT * FROM sub_a
    UNION ALL
    SELECT * FROM sub_b
)
SELECT d_year,
       ca_state,
       SUM(cs_sales)       AS total_cs_sales,
       SUM(ss_sales)       AS total_ss_sales,
       SUM(ws_sales)       AS total_ws_sales,
       SUM(returns)        AS total_returns,
       SUM(inventory_qty)  AS total_inventory_qty,
       SUM(cs_orders)      AS total_cs_orders,
       SUM(ss_tickets)     AS total_ss_tickets,
       SUM(ws_orders)      AS total_ws_orders,
       SUM(wr_orders)      AS total_wr_orders
FROM unioned
GROUP BY ROLLUP(d_year, ca_state)
ORDER BY d_year NULLS LAST, ca_state NULLS LAST
LIMIT 100
