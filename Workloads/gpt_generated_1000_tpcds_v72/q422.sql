WITH store_agg AS (
   SELECT
     c.c_customer_sk,
     c.c_customer_id,
     p.p_promo_sk,
     p.p_promo_id,
     cd.cd_demo_sk,
     ca.ca_address_sk,
     SUM(ss.ss_net_paid)          AS total_sales,
     SUM(COALESCE(sr.sr_net_loss, 0)) AS total_returns,
     SUM(ss.ss_net_profit)        AS total_profit
   FROM store_sales ss
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN promotion p
     ON ss.ss_promo_sk = p.p_promo_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN customer_address ca
     ON ss.ss_addr_sk = ca.ca_address_sk
   LEFT JOIN store_returns sr
     ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
   WHERE c.c_birth_month IN (1, 3, 9, 10)
     AND cd.cd_purchase_estimate >= 1000
     AND p.p_discount_active = 'Y'
     AND ca.ca_country = 'United States'
   GROUP BY c.c_customer_sk, c.c_customer_id, p.p_promo_sk, p.p_promo_id, cd.cd_demo_sk, ca.ca_address_sk
)
SELECT
  agg.p_promo_id,
  COUNT(DISTINCT agg.c_customer_id)          AS num_customers,
  AVG(agg.total_sales)                      AS avg_sales_per_customer,
  SUM(ws.ws_net_paid)                       AS total_web_sales,
  SUM(ws.ws_net_profit)                     AS total_web_profit,
  (SELECT MAX(p2.p_cost)
     FROM promotion p2
    WHERE p2.p_discount_active = 'Y')   AS max_active_promo_cost
FROM store_agg agg
JOIN web_sales ws
  ON ws.ws_bill_customer_sk = agg.c_customer_sk
 AND ws.ws_bill_cdemo_sk   = agg.cd_demo_sk
 AND ws.ws_bill_addr_sk    = agg.ca_address_sk
 AND ws.ws_promo_sk        = agg.p_promo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site wsite
  ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE wp.wp_type = 'product'
  AND wsite.web_country = 'United States'
  AND agg.total_sales > (
        SELECT AVG(ss2.ss_net_paid)
          FROM store_sales ss2
         WHERE ss2.ss_sold_date_sk > 2450000
      )
GROUP BY agg.p_promo_id
HAVING COUNT(DISTINCT agg.c_customer_id) >= 2
ORDER BY avg_sales_per_customer DESC
LIMIT 100
