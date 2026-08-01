WITH catalog_agg AS (
  SELECT
    c.c_customer_id AS customer_id,
    p.p_promo_sk   AS promo_sk,
    p.p_promo_id   AS promo_id,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    CASE
      WHEN SUM(cs.cs_quantity) > 100 THEN 'High'
      ELSE 'Low'
    END AS volume_category,
    CASE
      WHEN SUM(cs.cs_ext_sales_price) > (SELECT AVG(cs2.cs_ext_sales_price) FROM tpcds.catalog_sales cs2) THEN 'Above Avg'
      ELSE 'Below Avg'
    END AS sales_category
  FROM tpcds.catalog_sales cs
  JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  WHERE p.p_channel_email = 'N'
    AND cp.cp_department = 'Electronics'
    AND EXISTS (
          SELECT 1 FROM tpcds.customer_address ca
          WHERE ca.ca_address_sk = cs.cs_bill_addr_sk
            AND ca.ca_state = 'CA'
        )
  GROUP BY c.c_customer_id, p.p_promo_sk, p.p_promo_id
),
web_agg AS (
  SELECT
    c.c_customer_id AS customer_id,
    p.p_promo_sk   AS promo_sk,
    p.p_promo_id   AS promo_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    CASE
      WHEN SUM(ws.ws_quantity) > 100 THEN 'High'
      ELSE 'Low'
    END AS volume_category,
    CASE
      WHEN SUM(ws.ws_ext_sales_price) > (SELECT AVG(ws2.ws_ext_sales_price) FROM tpcds.web_sales ws2) THEN 'Above Avg'
      ELSE 'Below Avg'
    END AS sales_category
  FROM tpcds.web_sales ws
  JOIN tpcds.customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN tpcds.promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN tpcds.web_site w
    ON ws.ws_web_site_sk = w.web_site_sk
  WHERE w.web_class = 'Unknown'
    AND EXISTS (
          SELECT 1 FROM tpcds.customer_address ca
          WHERE ca.ca_address_sk = ws.ws_bill_addr_sk
            AND ca.ca_state = 'CA'
        )
  GROUP BY c.c_customer_id, p.p_promo_sk, p.p_promo_id
),
combined AS (
  SELECT * FROM catalog_agg
  UNION ALL
  SELECT * FROM web_agg
)
SELECT
  customer_id,
  promo_id,
  total_sales,
  volume_category,
  sales_category
FROM combined ua
WHERE NOT EXISTS (
        SELECT 1 FROM tpcds.promotion p2
        WHERE p2.p_promo_sk = ua.promo_sk
          AND p2.p_channel_email = 'Y'
      )
ORDER BY total_sales DESC
LIMIT 100
