/*
  Goal: Calculate yearly store and web sales totals by shipping carrier and website state, include return losses, count distinct orders, and rank carriers by total store sales within each year.
*/
WITH joined AS (
    SELECT
        d_sold.d_year AS sale_year,
        sm.sm_carrier,
        wsite.web_state,
        ss.ss_net_paid AS store_sales_net,
        sr.sr_net_loss AS store_return_loss,
        ws.ws_net_paid AS web_sales_net,
        ss.ss_ticket_number AS ticket_number
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN customer c_ss
        ON ss.ss_customer_sk = c_ss.c_customer_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN customer c_ret
        ON sr.sr_customer_sk = c_ret.c_customer_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
        AND ws.ws_bill_customer_sk = c_ss.c_customer_sk
    JOIN date_dim d_ws_ship
        ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
    JOIN customer c_ship
        ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d_open
        ON wsite.web_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON wsite.web_close_date_sk = d_close.d_date_sk
    LEFT JOIN date_dim d_cust_first_sales
        ON c_ss.c_first_sales_date_sk = d_cust_first_sales.d_date_sk
)
SELECT
    sale_year,
    sm_carrier,
    web_state,
    SUM(store_sales_net) AS total_store_sales,
    SUM(COALESCE(store_return_loss, 0)) AS total_return_loss,
    SUM(web_sales_net) AS total_web_sales,
    COUNT(DISTINCT ticket_number) AS distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY sale_year ORDER BY SUM(store_sales_net) DESC) AS sales_rank_by_year
FROM joined
GROUP BY
    sale_year,
    sm_carrier,
    web_state
ORDER BY
    total_store_sales DESC
LIMIT 100
