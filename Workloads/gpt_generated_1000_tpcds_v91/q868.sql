WITH sales_a AS (
   SELECT d.d_year,
          w.web_name,
          s.s_state,
          t.t_hour,
          ws.ws_net_paid,
          ws.ws_sales_price,
          ws.ws_order_number,
          ws.ws_ext_discount_amt,
          ws.ws_ext_tax,
          i.inv_quantity_on_hand
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   JOIN inventory i ON i.inv_date_sk = d.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_current_month = 'Y'
     AND d.d_qoy = 2
     AND i.inv_quantity_on_hand > 0
     AND EXISTS (
         SELECT 1 FROM call_center cc
         WHERE cc.cc_closed_date_sk = d.d_date_sk
           AND cc.cc_state = 'CA'
     )
     AND d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1998-04-01'
), sales_b AS (
   SELECT d.d_year,
          w.web_name,
          s.s_state,
          t.t_hour,
          ws.ws_net_paid,
          ws.ws_sales_price,
          ws.ws_order_number,
          ws.ws_ext_discount_amt,
          ws.ws_ext_tax,
          i.inv_quantity_on_hand
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
   JOIN inventory i ON i.inv_date_sk = d.d_date_sk
   JOIN store s ON s.s_closed_date_sk = d.d_date_sk
   WHERE d.d_current_month = 'Y'
     AND d.d_qoy = 2
     AND i.inv_quantity_on_hand > 0
     AND EXISTS (
         SELECT 1 FROM call_center cc
         WHERE cc.cc_closed_date_sk = d.d_date_sk
           AND cc.cc_state = 'CA'
     )
     AND d.d_date >= DATE '1998-04-01' AND d.d_date < DATE '1998-07-01'
)
SELECT
    d_year,
    web_name,
    s_state,
    t_hour,
    SUM(total_net_paid) AS total_net_paid,
    AVG(avg_sales_price) AS avg_sales_price,
    SUM(num_orders) AS total_orders,
    MIN(min_discount) AS min_discount,
    MAX(max_tax) AS max_tax
FROM (
    SELECT
        d_year,
        web_name,
        s_state,
        t_hour,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        MIN(ws_ext_discount_amt) AS min_discount,
        MAX(ws_ext_tax) AS max_tax
    FROM sales_a
    GROUP BY GROUPING SETS ((d_year, web_name), (s_state), (t_hour))
    UNION
    SELECT
        d_year,
        web_name,
        s_state,
        t_hour,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        MIN(ws_ext_discount_amt) AS min_discount,
        MAX(ws_ext_tax) AS max_tax
    FROM sales_b
    GROUP BY GROUPING SETS ((d_year, web_name), (s_state), (t_hour))
) agg
GROUP BY d_year, web_name, s_state, t_hour
ORDER BY total_net_paid DESC
LIMIT 100
