SELECT d_year,
       s_state,
       c_customer_id,
       total_paid,
       total_profit,
       rank
FROM (
    SELECT d.d_year,
           s.s_state,
           c.c_customer_id,
           SUM(ss.ss_net_paid) AS total_paid,
           SUM(ss.ss_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY d.d_year, s.s_state ORDER BY SUM(ss.ss_net_paid) DESC) AS rank
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, s.s_state, c.c_customer_id
) t
WHERE rank <= 5
ORDER BY d_year, s_state, rank
