WITH morning_2001 AS (
    SELECT d.d_year,
           ca.ca_city,
           t.t_shift,
           SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND t.t_shift = 'morning'
      AND ca.ca_street_name LIKE 'Jackson%'
    GROUP BY d.d_year, ca.ca_city, t.t_shift
    HAVING SUM(ss.ss_net_paid) > 1000
),

evening_2002 AS (
    SELECT d.d_year,
           ca.ca_city,
           t.t_shift,
           SUM(ss.ss_net_paid) AS total_net_paid
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND t.t_shift = 'evening'
      AND ca.ca_street_name LIKE 'Elm%'
    GROUP BY d.d_year, ca.ca_city, t.t_shift
    HAVING SUM(ss.ss_net_paid) > 1000
)
SELECT d_year,
       ca_city,
       t_shift,
       total_net_paid
FROM morning_2001
UNION ALL
SELECT d_year,
       ca_city,
       t_shift,
       total_net_paid
FROM evening_2002
ORDER BY d_year, ca_city, t_shift
