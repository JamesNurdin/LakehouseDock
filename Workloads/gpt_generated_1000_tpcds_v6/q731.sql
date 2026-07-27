WITH sales_per_customer AS (
  SELECT
    c.c_customer_id AS customer_id,
    cp.cp_department AS department,
    p.p_promo_name AS promo_name,
    SUM(cs.cs_net_paid_inc_ship) AS catalog_sales_total,
    SUM(ss.ss_net_paid) AS store_sales_total,
    SUM(ws.ws_net_paid) AS web_sales_total,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_tickets,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders,
    SUM(
      CASE
        WHEN cs.cs_net_paid_inc_ship > 3000 THEN cs.cs_net_paid_inc_ship
        ELSE 0
      END
    ) AS high_value_catalog_sales
  FROM catalog_page cp
  JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c
    ON c.c_customer_sk = cs.cs_bill_customer_sk
  JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN promotion p
    ON p.p_promo_sk = ss.ss_promo_sk
  JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_site w
    ON w.web_site_sk = ws.ws_web_site_sk
  WHERE cp.cp_department = 'Electronics'
    AND cs.cs_net_paid_inc_ship > 1000
    AND w.web_rec_start_date >= DATE '1999-01-01'
    AND ss.ss_quantity > 5
  GROUP BY
    c.c_customer_id,
    cp.cp_department,
    p.p_promo_name
)
SELECT
  department,
  promo_name,
  COUNT(*) AS num_customers,
  SUM(catalog_sales_total) AS total_catalog_sales,
  SUM(store_sales_total) AS total_store_sales,
  SUM(web_sales_total) AS total_web_sales,
  AVG(high_value_catalog_sales) AS avg_high_value_catalog_sales
FROM sales_per_customer
GROUP BY
  department,
  promo_name
HAVING
  SUM(catalog_sales_total) > 5000
  AND SUM(store_sales_total) > 2000
  AND COUNT(*) >= 10
ORDER BY total_catalog_sales DESC
LIMIT 100
