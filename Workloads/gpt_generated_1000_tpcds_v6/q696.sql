WITH store_web AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ss.ss_sales_price,
        ss.ss_ticket_number,
        ws.ws_sold_date_sk,
        ws.ws_sold_time_sk,
        ws.ws_ext_tax,
        ws.ws_net_paid_inc_ship,
        ws.ws_web_site_sk,
        wsite.web_state,
        d1.d_year,
        t1.t_shift,
        d3.d_year AS open_year,
        d4.d_year AS close_year
    FROM store_sales ss
    JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
    JOIN time_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN date_dim d3 ON wsite.web_open_date_sk = d3.d_date_sk
    JOIN date_dim d4 ON wsite.web_close_date_sk = d4.d_date_sk
    WHERE d1.d_year = 1999
      AND t1.t_shift = 'first'
      AND ws.ws_ext_tax > 15.00
      AND ws.ws_net_paid_inc_ship BETWEEN 2000 AND 5000
      AND wsite.web_state = 'CA'
      AND ss.ss_quantity >= 2
      AND d3.d_year = 1999
      AND ss.ss_ext_discount_amt > (
          SELECT AVG(ss2.ss_ext_discount_amt)
          FROM store_sales ss2
          WHERE ss2.ss_sold_date_sk = ss.ss_sold_date_sk
      )
)
SELECT
    d_year,
    web_state,
    SUM(ss_net_paid) AS total_store_net_paid,
    SUM(ws_net_paid_inc_ship) AS total_web_net_paid_inc_ship,
    AVG(ss_ext_discount_amt) AS avg_store_discount,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
    MIN(ws_ext_tax) AS min_web_tax,
    MAX(ss_sales_price) AS max_store_sales_price
FROM (
    SELECT
        d_year,
        web_state,
        ss_net_paid,
        ws_net_paid_inc_ship,
        ss_ext_discount_amt,
        ss_ticket_number,
        ws_ext_tax,
        ss_sales_price
    FROM store_web
) agg
GROUP BY GROUPING SETS (
    (d_year, web_state),
    (d_year),
    (web_state),
    ()
)
ORDER BY total_store_net_paid DESC
LIMIT 100
