WITH sales_address AS (
  SELECT
    ca.ca_address_sk,
    ca.ca_state,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM catalog_sales cs
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN web_sales ws     ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE cs.cs_net_paid_inc_ship > 1000
    AND ws.ws_net_paid_inc_ship_tax < 5000
    AND cs.cs_list_price BETWEEN 100 AND 200
  GROUP BY ca.ca_address_sk, ca.ca_state
),
address_with_returns AS (
  SELECT
    ca_state,
    total_catalog_sales,
    total_web_sales,
    catalog_orders,
    web_orders
  FROM sales_address sa
  WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    JOIN customer_address ca2 ON sr.sr_addr_sk = ca2.ca_address_sk
    WHERE ca2.ca_state = sa.ca_state
      AND sr.sr_fee > 20
      AND sr.sr_return_amt > 100
  )
)
SELECT
  ca_state AS state,
  SUM(total_catalog_sales) AS sum_catalog_sales,
  SUM(total_web_sales)    AS sum_web_sales,
  SUM(total_catalog_sales + total_web_sales) AS total_sales,
  SUM(catalog_orders) AS total_catalog_orders,
  SUM(web_orders)    AS total_web_orders,
  SUM(total_catalog_sales + total_web_sales) / NULLIF(SUM(catalog_orders + web_orders), 0) AS avg_sale_per_order
FROM address_with_returns
GROUP BY ca_state
HAVING SUM(total_catalog_sales + total_web_sales) > 10000
ORDER BY total_sales DESC
LIMIT 100
