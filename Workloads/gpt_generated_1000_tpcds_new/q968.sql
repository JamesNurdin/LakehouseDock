WITH sales_agg AS (
   SELECT
       c.c_customer_sk,
       SUM(cs.cs_net_paid_inc_ship_tax) AS total_catalog_net,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_catalog_orders,
       SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END) AS positive_catalog_profit,
       MIN(cs.cs_quantity) AS min_catalog_qty
   FROM catalog_sales cs
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   WHERE cp.cp_department = 'DEPARTMENT'
     AND w.w_warehouse_sq_ft > 20000
     AND cd.cd_dep_employed_count >= 3
     AND cs.cs_quantity > 1
     AND cs.cs_net_paid_inc_ship_tax > 500
   GROUP BY c.c_customer_sk
),

web_agg AS (
   SELECT
       c.c_customer_sk,
       SUM(ws.ws_net_paid_inc_ship_tax) AS total_web_net,
       COUNT(DISTINCT ws.ws_order_number) AS distinct_web_orders,
       SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_net_profit ELSE 0 END) AS positive_web_profit,
       MIN(ws.ws_quantity) AS min_web_qty
   FROM web_sales ws
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
   JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   WHERE wp.wp_char_count > 1000
     AND w.w_warehouse_sq_ft > 20000
     AND cd.cd_dep_employed_count >= 3
     AND ws.ws_quantity >= 2
     AND ws.ws_net_paid_inc_ship_tax > 600
   GROUP BY c.c_customer_sk
),

returns_agg AS (
   SELECT
       c.c_customer_sk,
       COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
       SUM(sr.sr_net_loss) AS total_return_loss,
       SUM(CASE WHEN sr.sr_return_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_returns
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
   WHERE cd.cd_dep_college_count >= 2
     AND sr.sr_return_amt > 100
   GROUP BY c.c_customer_sk
),

customer_set_a AS (
   SELECT c_customer_sk FROM sales_agg WHERE total_catalog_net > 1000
),

customer_set_b AS (
   SELECT c_customer_sk FROM web_agg WHERE total_web_net > 1200
),

intersect_customers AS (
   SELECT c_customer_sk FROM customer_set_a
   INTERSECT
   SELECT c_customer_sk FROM customer_set_b
)
SELECT
    ic.c_customer_sk,
    sa.total_catalog_net,
    wa.total_web_net,
    ra.distinct_return_tickets,
    sa.distinct_catalog_orders,
    wa.distinct_web_orders,
    CASE
        WHEN sa.total_catalog_net > wa.total_web_net THEN 'CatalogHigher'
        WHEN wa.total_web_net > sa.total_catalog_net THEN 'WebHigher'
        ELSE 'Equal'
    END AS net_comparison
FROM intersect_customers ic
JOIN sales_agg sa ON ic.c_customer_sk = sa.c_customer_sk
JOIN web_agg wa ON ic.c_customer_sk = wa.c_customer_sk
LEFT JOIN returns_agg ra ON ic.c_customer_sk = ra.c_customer_sk
ORDER BY net_comparison, sa.total_catalog_net DESC
LIMIT 100
