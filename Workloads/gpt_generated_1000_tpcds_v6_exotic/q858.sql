WITH catalog_totals AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(cs.cs_net_paid) AS total_sales,
        'Catalog' AS channel
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_quantity > 1
      AND hd.hd_vehicle_count >= 2
      AND hd.hd_dep_count > 0
      AND NOT EXISTS (
          SELECT 1 FROM catalog_sales cs2
          WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
            AND cs2.cs_ext_discount_amt > 100
      )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
web_totals AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        'Web' AS channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_quantity > 1
      AND w.web_tax_percentage > 0.05
      AND hd.hd_vehicle_count >= 2
      AND hd.hd_dep_count > 0
      AND NOT EXISTS (
          SELECT 1 FROM web_sales ws2
          WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
            AND ws2.ws_ext_discount_amt > 100
      )
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT first_name, last_name, total_sales, channel
FROM (
    SELECT c_first_name AS first_name,
           c_last_name  AS last_name,
           total_sales,
           channel
    FROM catalog_totals
    UNION ALL
    SELECT c_first_name AS first_name,
           c_last_name  AS last_name,
           total_sales,
           channel
    FROM web_totals
) AS combined
ORDER BY total_sales DESC
LIMIT 100
