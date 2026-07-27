WITH
  billed_sales AS (
    SELECT
      ca.ca_county,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      'Billed' AS address_role
    FROM
      web_sales ws
      JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE
      ca.ca_state = 'CA'
      AND ws.ws_ext_sales_price > 2000
    GROUP BY
      ca.ca_county
  ),
  shipped_sales AS (
    SELECT
      ca.ca_county,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
      'Shipped' AS address_role
    FROM
      web_sales ws
      JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    WHERE
      ca.ca_state = 'NY'
      AND ws.ws_ext_sales_price > 1500
    GROUP BY
      ca.ca_county
  )
SELECT
  ca_county,
  total_sales,
  distinct_orders,
  address_role
FROM billed_sales
UNION ALL
SELECT
  ca_county,
  total_sales,
  distinct_orders,
  address_role
FROM shipped_sales
ORDER BY total_sales DESC
