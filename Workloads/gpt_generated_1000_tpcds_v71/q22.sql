WITH overall_store_avg AS (
    SELECT avg(ss_net_paid) AS avg_net_paid
    FROM store_sales
),
store_agg AS (
    SELECT
        td.t_shift,
        td.t_hour,
        sum(ss.ss_net_paid) AS total_net_paid,
        avg(ss.ss_net_paid) AS avg_net_paid,
        sum(ss.ss_net_profit) AS total_profit,
        CASE WHEN sum(ss.ss_net_profit) > 1000 THEN 'high' ELSE 'low' END AS profit_category,
        (SELECT avg_net_paid FROM overall_store_avg) AS overall_avg_net_paid
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE td.t_shift = 'first'
      AND ss.ss_net_paid > 0
      AND c.c_customer_sk IN (
          SELECT c2.c_customer_sk
          FROM customer c2
          JOIN customer_address ca2 ON c2.c_current_addr_sk = ca2.ca_address_sk
          WHERE ca2.ca_state = 'CA'
      )
    GROUP BY td.t_shift, td.t_hour
    HAVING count(*) > 10
),
catalog_agg AS (
    SELECT
        td.t_shift,
        td.t_hour,
        sum(cs.cs_net_paid) AS total_net_paid,
        avg(cs.cs_net_paid) AS avg_net_paid,
        sum(cs.cs_net_profit) AS total_profit,
        CASE WHEN sum(cs.cs_net_profit) > 2000 THEN 'high' ELSE 'low' END AS profit_category,
        (SELECT avg_net_paid FROM overall_store_avg) AS overall_avg_net_paid
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE td.t_shift = 'second'
      AND cs.cs_net_paid > 0
      AND NOT EXISTS (
          SELECT 1
          FROM call_center cc
          WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
            AND cc.cc_tax_percentage > 0.10
      )
    GROUP BY td.t_shift, td.t_hour
    HAVING count(*) > 5
)
SELECT
    t_shift,
    t_hour,
    total_net_paid,
    avg_net_paid,
    total_profit,
    profit_category,
    overall_avg_net_paid
FROM store_agg
UNION ALL
SELECT
    t_shift,
    t_hour,
    total_net_paid,
    avg_net_paid,
    total_profit,
    profit_category,
    overall_avg_net_paid
FROM catalog_agg
ORDER BY t_shift, total_net_paid DESC
LIMIT 100
