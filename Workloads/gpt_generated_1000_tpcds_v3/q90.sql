WITH store_sales_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_addr_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_store_customers,
        MIN(ss.ss_ext_sales_price) AS min_store_sale,
        MAX(ss.ss_ext_sales_price) AS max_store_sale
    FROM store_sales ss
    WHERE ss.ss_wholesale_cost IN (13.72, 28.99, 46.49)
      AND ss.ss_ext_sales_price > 1000.00
      AND ss.ss_quantity >= 10
    GROUP BY ss.ss_store_sk, ss.ss_addr_sk
)
SELECT
    ca.ca_city,
    s.s_store_name,
    s.s_state,
    s.s_gmt_offset,
    ss_agg.total_store_sales,
    ss_agg.avg_store_discount,
    ss_agg.distinct_store_customers,
    ss_agg.min_store_sale,
    ss_agg.max_store_sale,
    ws_agg.total_web_sales,
    ws_agg.avg_web_discount,
    ws_agg.distinct_web_customers,
    (
        SELECT AVG(ws2.ws_ext_discount_amt)
        FROM web_sales ws2
        WHERE ws2.ws_bill_addr_sk = ca.ca_address_sk
    ) AS avg_web_discount_city,
    (
        SELECT MAX(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_store_sk = s.s_store_sk
    ) AS max_store_sale_overall
FROM store_sales_agg ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON ss_agg.ss_addr_sk = ca.ca_address_sk
JOIN (
    SELECT
        ws.ws_bill_addr_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_web_customers
    FROM web_sales ws
    WHERE ws.ws_web_page_sk = 1105
      AND ws.ws_net_paid_inc_ship_tax < 2000.00
      AND ws.ws_ext_wholesale_cost > 500.00
    GROUP BY ws.ws_bill_addr_sk
) ws_agg ON ws_agg.ws_bill_addr_sk = ca.ca_address_sk
WHERE s.s_state = 'CA'
  AND s.s_gmt_offset = -7.00
  AND ca.ca_country = 'United States'
  AND ca.ca_city IN (
        SELECT DISTINCT ca_sub.ca_city
        FROM customer_address ca_sub
        WHERE ca_sub.ca_state = 'TX'
    )
  AND EXISTS (
        SELECT 1
        FROM web_sales ws_check
        WHERE ws_check.ws_bill_addr_sk = ca.ca_address_sk
          AND ws_check.ws_net_paid_inc_ship_tax > 1500
    )
LIMIT 100
