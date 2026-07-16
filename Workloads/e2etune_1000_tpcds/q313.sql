WITH sales_agg AS (
    SELECT cp.cp_department,
           ca.ca_city,
           SUM(cs.cs_net_paid) AS total_sales,
           SUM(cs.cs_net_profit) AS total_profit,
           COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_start_date_sk BETWEEN 2450800 AND 2450900
      AND cs.cs_quantity > 1
      AND ca.ca_city = 'San Francisco'
    GROUP BY cp.cp_department, ca.ca_city
),
returns_agg AS (
    SELECT ca.ca_city,
           r.r_reason_desc,
           SUM(sr.sr_net_loss) AS total_loss,
           COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE ca.ca_city = 'San Francisco'
      AND sr.sr_return_quantity > 0
      AND sr.sr_returned_date_sk BETWEEN 2450800 AND 2450900
    GROUP BY ca.ca_city, r.r_reason_desc
)
SELECT s.cp_department,
       s.ca_city,
       s.total_sales,
       s.total_profit,
       r.r_reason_desc,
       r.total_loss,
       (s.total_sales - COALESCE(r.total_loss, 0)) AS net_revenue,
       s.sales_cnt,
       r.returns_cnt
FROM sales_agg s
LEFT JOIN returns_agg r ON s.ca_city = r.ca_city
WHERE (s.total_sales - COALESCE(r.total_loss, 0)) > 1000
ORDER BY net_revenue DESC
LIMIT 100
