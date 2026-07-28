WITH joined_data AS (
    SELECT
        ca.ca_state,
        sm.sm_code,
        d.d_date,
        ss.ss_net_paid AS ss_net_paid,
        cs.cs_net_paid AS cs_net_paid,
        ss.ss_quantity AS ss_qty,
        cs.cs_quantity AS cs_qty
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
       AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date >= DATE '2001-01-01'
      AND d.d_date < DATE '2002-01-01'
      AND sm.sm_code = 'AIR'
      AND ca.ca_state NOT IN ('TX', 'NY')
      AND NOT EXISTS (
          SELECT 1
          FROM inventory i
          WHERE i.inv_date_sk = d.d_date_sk
      )
)
SELECT
    ca_state,
    sm_code,
    COUNT(*) AS days_count,
    SUM(ss_net_paid + cs_net_paid) AS total_net_paid,
    AVG(ss_net_paid + cs_net_paid) AS avg_daily_net_paid,
    (SELECT MAX(cs_net_paid) FROM catalog_sales) AS max_cs_net_paid_overall
FROM joined_data
GROUP BY ca_state, sm_code
HAVING SUM(ss_net_paid + cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
