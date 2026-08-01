WITH base AS (
    SELECT
        d.d_year,
        d.d_date,
        ca.ca_state,
        ws.ws_order_number,
        ws.ws_net_profit,
        sr.sr_net_loss,
        cr.cr_net_loss,
        wr.wr_net_loss,
        sr.sr_return_tax,
        cr.cr_return_tax,
        wr.wr_return_tax,
        ws.ws_quantity,
        sr.sr_return_quantity,
        cr.cr_return_quantity,
        wr.wr_return_quantity
    FROM date_dim d
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
         AND wr.wr_order_number = ws.ws_order_number
         AND wr.wr_item_sk = ws.ws_item_sk
    JOIN customer c
      ON c.c_customer_sk = sr.sr_customer_sk
    JOIN customer_address ca
      ON ca.ca_address_sk = sr.sr_addr_sk
    JOIN warehouse w1
      ON w1.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN warehouse w2
      ON w2.w_warehouse_sk = ws.ws_warehouse_sk
    JOIN web_page wp
      ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN web_site we
      ON we.web_site_sk = ws.ws_web_site_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND ca.ca_state = 'CA'
      AND w1.w_state = 'CA'
      AND w2.w_state = 'CA'
      AND c.c_birth_country = 'United States'
      AND sr.sr_return_tax > 1.00
      AND ws.ws_quantity > 5
),
intersect_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 10
    INTERSECT
    SELECT sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 5
),
except_orders AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_quantity > 10
    EXCEPT
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_quantity > 5
),
filtered AS (
    SELECT
        d_year,
        ca_state,
        ws_order_number,
        ws_net_profit,
        sr_net_loss,
        cr_net_loss,
        wr_net_loss,
        sr_return_tax,
        cr_return_tax,
        wr_return_tax,
        ws_quantity
    FROM base b
    WHERE b.ws_order_number IN (SELECT ws_order_number FROM intersect_orders)
      AND b.ws_order_number NOT IN (SELECT ws_order_number FROM except_orders)
)
SELECT
    f.d_year AS year,
    f.ca_state AS state,
    SUM(f.ws_net_profit) AS total_net_profit,
    SUM(f.sr_net_loss) AS total_store_return_loss,
    SUM(f.cr_net_loss) AS total_catalog_return_loss,
    SUM(f.wr_net_loss) AS total_web_return_loss,
    AVG(f.sr_return_tax) AS avg_store_return_tax,
    COUNT(DISTINCT f.ws_order_number) AS distinct_orders
FROM filtered f
GROUP BY f.d_year, f.ca_state
HAVING SUM(f.ws_net_profit) > 10000
ORDER BY year DESC, state
LIMIT 100
