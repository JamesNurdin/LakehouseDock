WITH catalog AS (
    SELECT cs.cs_order_number,
           cs.cs_net_paid_inc_tax,
           cs.cs_sales_price,
           cs.cs_sold_date_sk,
           cs.cs_bill_customer_sk,
           cs.cs_promo_sk
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450845
)
SELECT p.p_promo_id,
       wp.wp_type,
       COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
       SUM(catalog.cs_net_paid_inc_tax) AS total_catalog_sales,
       SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
       SUM(sr.sr_net_loss) AS total_store_returns_loss,
       AVG(catalog.cs_sales_price) AS avg_catalog_sales_price,
       MIN(catalog.cs_sold_date_sk) AS min_sold_date_sk,
       MAX(catalog.cs_sold_date_sk) AS max_sold_date_sk
FROM catalog
JOIN customer c
  ON catalog.cs_bill_customer_sk = c.c_customer_sk
JOIN promotion p
  ON catalog.cs_promo_sk = p.p_promo_sk
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN store_returns sr
  ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_month = 6
  AND p.p_channel_demo = 'N'
  AND p.p_start_date_sk >= 2450600
  AND wp.wp_type = 'content'
  AND sr.sr_net_loss > 0
GROUP BY p.p_promo_id, wp.wp_type
ORDER BY total_catalog_sales DESC
LIMIT 100
