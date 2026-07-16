SELECT
    g.d_year,
    g.i_category,
    g.s_state,
    g.total_net_paid,
    g.total_net_profit,
    g.sales_count,
    RANK() OVER (PARTITION BY g.d_year ORDER BY g.total_net_paid DESC) AS revenue_rank
FROM (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE d.d_year BETWEEN 1998 AND 1999
      AND (c.c_preferred_cust_flag = 'Y' OR ca.ca_country = 'United States')
    GROUP BY d.d_year, i.i_category, s.s_state
) AS g
WHERE g.total_net_paid > 1000000
ORDER BY g.d_year, revenue_rank
LIMIT 10
