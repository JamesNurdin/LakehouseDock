WITH cs_customers AS (
  SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk,
         cs.cs_promo_sk AS promo_sk
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
                     AND cs.cs_item_sk = inv.inv_item_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  WHERE cc.cc_state = 'CA'
    AND w.w_city = 'Seattle'
    AND t.t_hour BETWEEN 9 AND 17
    AND cs.cs_ext_sales_price > 1000
    AND inv.inv_quantity_on_hand > 0
),
ss_customers AS (
  SELECT DISTINCT ss.ss_customer_sk AS customer_sk
  FROM store_sales ss
  JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk
                         AND ss.ss_ticket_number = sr.sr_ticket_number
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  WHERE r.r_reason_desc = 'Damaged'
    AND ss.ss_quantity > 1
    AND ss.ss_ext_sales_price > 500
    AND t.t_hour BETWEEN 10 AND 18
),
ws_customers AS (
  SELECT DISTINCT ws.ws_bill_customer_sk AS customer_sk
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  WHERE wp.wp_type = 'home'
    AND wsite.web_state = 'CA'
    AND t.t_hour BETWEEN 8 AND 20
    AND ws.ws_ext_sales_price > 200
),
intersect_customers AS (
  SELECT customer_sk FROM cs_customers
  INTERSECT
  SELECT customer_sk FROM ss_customers
  INTERSECT
  SELECT customer_sk FROM ws_customers
),
agg_sales AS (
  SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    MIN(cs.cs_promo_sk) AS promo_sk,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(cs.cs_net_profit)      AS catalog_profit,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    SUM(ws.ws_ext_sales_price) AS web_sales_total
  FROM intersect_customers ic
  JOIN customer c ON ic.customer_sk = c.c_customer_sk
  LEFT JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
  LEFT JOIN store_sales ss   ON ss.ss_customer_sk   = c.c_customer_sk
  LEFT JOIN web_sales ws    ON ws.ws_bill_customer_sk = c.c_customer_sk
  GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
final_result AS (
  SELECT
    a.c_customer_id   AS customer_id,
    a.c_first_name    AS first_name,
    a.c_last_name     AS last_name,
    a.catalog_sales_total,
    a.store_sales_total,
    a.web_sales_total,
    a.catalog_profit,
    CASE WHEN a.catalog_profit > 0 THEN 'Profitable' ELSE 'Unprofitable' END AS profit_flag,
    -- correlated scalar subquery: number of distinct promotions used by this customer
    (SELECT COUNT(DISTINCT cs2.cs_promo_sk)
     FROM catalog_sales cs2
     WHERE cs2.cs_bill_customer_sk = c.c_customer_sk) AS distinct_promos_used
  FROM agg_sales a
  JOIN customer c ON a.c_customer_id = c.c_customer_id
  RIGHT JOIN promotion p ON a.promo_sk = p.p_promo_sk
  WHERE c.c_preferred_cust_flag = 'Y'
)
SELECT *
FROM final_result
ORDER BY catalog_sales_total DESC
LIMIT 100
