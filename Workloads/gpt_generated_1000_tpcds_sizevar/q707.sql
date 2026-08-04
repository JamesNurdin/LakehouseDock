WITH sampled_item AS (
   SELECT *
   FROM item
   TABLESAMPLE BERNOULLI (10)
),

store_data AS (
   SELECT
       ss.ss_ticket_number,
       ss.ss_sold_date_sk,
       ss.ss_quantity,
       ss.ss_net_paid,
       i.i_item_id,
       c.c_customer_id,
       p.p_promo_name,
       r.r_reason_desc,
       t.t_hour,
       CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
   FROM store_sales ss
   JOIN sampled_item i ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
   JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
   JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
   LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
),

web_data AS (
   SELECT
       ws.ws_order_number,
       ws.ws_sold_date_sk,
       ws.ws_quantity,
       ws.ws_net_paid,
       i.i_item_id,
       cb.c_customer_id AS bill_customer_id,
       cs.c_customer_id AS ship_customer_id,
       p.p_promo_name,
       r.r_reason_desc,
       t.t_hour,
       wh.w_warehouse_name,
       wp.wp_url,
       site.web_name,
       CASE WHEN ws.ws_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
   FROM web_sales ws
   JOIN sampled_item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer cb ON ws.ws_bill_customer_sk = cb.c_customer_sk
   JOIN customer cs ON ws.ws_ship_customer_sk = cs.c_customer_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN warehouse wh ON ws.ws_warehouse_sk = wh.w_warehouse_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
),

combined AS (
   SELECT
       sd.ss_ticket_number AS order_id,
       sd.i_item_id,
       sd.c_customer_id AS customer_id,
       sd.ss_quantity AS quantity,
       sd.ss_net_paid AS net_paid,
       sd.profit_flag,
       'store' AS channel
   FROM store_data sd
   FULL OUTER JOIN web_data wd
     ON sd.i_item_id = wd.i_item_id
    AND sd.c_customer_id = wd.bill_customer_id
),

combined_lateral AS (
   SELECT
       c.*,
       lt.quantity_type
   FROM combined c
   CROSS JOIN LATERAL (
       SELECT CASE WHEN c.quantity > 10 THEN 'BULK' ELSE 'REG' END AS quantity_type
   ) lt
),

item_agg AS (
   SELECT
       cla.i_item_id,
       SUM(cla.quantity) AS total_quantity,
       SUM(cla.net_paid) AS total_revenue,
       COUNT(DISTINCT cla.customer_id) AS distinct_customers
   FROM combined_lateral cla
   GROUP BY cla.i_item_id
),

final_set AS (
   SELECT
       ia.i_item_id,
       ia.total_quantity,
       ia.total_revenue,
       ia.distinct_customers,
       CASE WHEN ia.total_revenue > 10000 THEN 'HIGH' ELSE 'LOW' END AS revenue_category
   FROM item_agg ia
)

SELECT *
FROM final_set
UNION DISTINCT
SELECT
   i.i_item_id,
   0 AS total_quantity,
   0.0 AS total_revenue,
   0 AS distinct_customers,
   'NONE' AS revenue_category
FROM sampled_item i
WHERE NOT EXISTS (
   SELECT 1 FROM final_set f WHERE f.i_item_id = i.i_item_id
)
EXCEPT
SELECT
   i.i_item_id,
   0,
   0.0,
   0,
   'NONE'
FROM sampled_item i
WHERE i.i_color = 'RED'
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
