/*
  Goal: Analyze web sales performance for California customers in York County who are college‑educated, grouping by promotion and website, and compare married vs other marital status. The query joins all five TPC‑DS tables, applies several realistic filters, uses a CTE, a LATERAL subquery, an IN‑subquery filter, DISTINCT aggregates and a CASE expression.
*/
WITH filtered_sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_addr_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk
    FROM web_sales ws
    WHERE ws.ws_promo_sk IN (
        SELECT p.p_promo_sk
        FROM promotion p
        WHERE p.p_discount_active = 'Y'
    )
      AND ws.ws_quantity > 2
)
SELECT
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_web_site_sk,
    ws.ws_promo_sk,
    ca.ca_state,
    ca.ca_county,
    ca.ca_location_type,
    cd.cd_education_status,
    CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END AS marital_category,
    p.p_promo_name,
    lt.total_price,
    lt.avg_price_per_item,
    SUM(ws.ws_net_paid)                         AS total_net_paid,
    AVG(ws.ws_ext_sales_price)                  AS avg_ext_sales_price,
    COUNT(DISTINCT ws.ws_order_number)          AS distinct_orders,
    COUNT(DISTINCT ca.ca_address_sk)            AS distinct_addresses,
    MIN(ws.ws_net_paid)                         AS min_net_paid,
    MAX(ws.ws_net_paid)                         AS max_net_paid
FROM filtered_sales ws
JOIN customer_address ca
  ON ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd
  ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
  ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site ws_site
  ON ws.ws_web_site_sk = ws_site.web_site_sk
CROSS JOIN LATERAL (
    SELECT
        ws.ws_ext_sales_price / NULLIF(ws.ws_quantity, 0) AS price_per_item,
        ws.ws_ext_sales_price                         AS total_price,
        ws.ws_ext_sales_price / ws.ws_quantity        AS avg_price_per_item
) AS lt
WHERE ca.ca_state = 'CA'
  AND ca.ca_county = 'York County'
  AND cd.cd_education_status = 'College'
  AND p.p_channel_demo = 'N'
GROUP BY
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    ws.ws_web_site_sk,
    ws.ws_promo_sk,
    ca.ca_state,
    ca.ca_county,
    ca.ca_location_type,
    cd.cd_education_status,
    CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Other' END,
    p.p_promo_name,
    lt.total_price,
    lt.avg_price_per_item
ORDER BY total_net_paid DESC
LIMIT 100
