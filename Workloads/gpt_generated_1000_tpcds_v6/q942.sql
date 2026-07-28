SELECT
    cp.cp_catalog_page_id,
    ws_site.web_name,
    cp.cp_department,
    ca_bc.ca_state,
    d_cs.d_year,
    SUM(cs.cs_net_paid) AS catalog_sales_net,
    SUM(ws.ws_net_paid) AS web_sales_net,
    SUM(sr.sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS num_web_orders
FROM catalog_sales cs
JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion promo_cs ON cs.cs_promo_sk = promo_cs.p_promo_sk
JOIN customer cust_bc ON cs.cs_bill_customer_sk = cust_bc.c_customer_sk
JOIN customer_address ca_bc ON cs.cs_bill_addr_sk = ca_bc.ca_address_sk
JOIN customer_demographics cd_bc ON cs.cs_bill_cdemo_sk = cd_bc.cd_demo_sk
-- Join web sales through the same date and time dimensions
JOIN web_sales ws ON ws.ws_sold_date_sk = d_cs.d_date_sk
               AND ws.ws_sold_time_sk = t_cs.t_time_sk
JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
JOIN promotion promo_ws ON ws.ws_promo_sk = promo_ws.p_promo_sk
-- Join store returns through the same date and time dimensions
JOIN store_returns sr ON sr.sr_returned_date_sk = d_cs.d_date_sk
                     AND sr.sr_return_time_sk = t_cs.t_time_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE promo_cs.p_discount_active = 'Y'
  AND ca_bc.ca_suite_number = 'Suite 200'
  -- Subquery: keep only customers whose total catalog net paid exceeds $5,000
  AND EXISTS (
        SELECT 1
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_customer_sk = cust_bc.c_customer_sk
        GROUP BY cs2.cs_bill_customer_sk
        HAVING SUM(cs2.cs_net_paid) > 5000
    )
GROUP BY
    cp.cp_catalog_page_id,
    ws_site.web_name,
    cp.cp_department,
    ca_bc.ca_state,
    d_cs.d_year
ORDER BY catalog_sales_net DESC
LIMIT 100
