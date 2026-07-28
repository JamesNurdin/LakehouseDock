WITH sales_agg AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS location,
        SUBSTRING(ca.ca_zip, 1, 3) AS zip_prefix,
        CASE WHEN ws.ws_ext_discount_amt > 100 THEN 'High Discount' ELSE 'Low Discount' END AS discount_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city LIKE 'San%'
      AND NOT EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
          WHERE sr.sr_addr_sk = ca.ca_address_sk
            AND regexp_like(r.r_reason_desc, '(?i)product')
      )
    GROUP BY
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_city, ', ', ca.ca_state),
        SUBSTRING(ca.ca_zip, 1, 3),
        CASE WHEN ws.ws_ext_discount_amt > 100 THEN 'High Discount' ELSE 'Low Discount' END
)
SELECT
    location,
    zip_prefix,
    discount_category,
    total_sales,
    order_cnt,
    CASE WHEN total_sales > 50000 THEN 'Top Performer' ELSE 'Regular' END AS performance_tier
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
