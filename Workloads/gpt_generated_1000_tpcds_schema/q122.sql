WITH joined AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_customer_sk,
       ss.ss_net_paid AS ss_net,
       ws.ws_order_number,
       ws.ws_bill_customer_sk,
       ws.ws_net_paid AS ws_net,
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       d.d_year,
       cc.cc_division_name,
       cp.cp_type,
       p.p_discount_active
   FROM store_sales ss
   JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
   JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
   JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN web_site we ON we.web_open_date_sk = d.d_date_sk
   WHERE d.d_year = 2001
     AND cc.cc_division_name = 'ese'
     AND cp.cp_type = 'Catalog'
     AND p.p_discount_active = 'Y'
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    SUM(ss_net) AS store_net,
    SUM(ws_net) AS web_net,
    SUM(ss_net) + SUM(ws_net) AS total_net,
    RANK() OVER (ORDER BY SUM(ss_net) + SUM(ws_net) DESC) AS revenue_rank
FROM joined
WHERE c_customer_id NOT IN (
    SELECT c2.c_customer_id
    FROM customer c2
    WHERE c2.c_preferred_cust_flag = 'Y'
)
GROUP BY c_customer_id, c_first_name, c_last_name
ORDER BY revenue_rank
LIMIT 50
