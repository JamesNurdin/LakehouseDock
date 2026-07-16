WITH sales_by_cc AS (
    SELECT 
        cc.cc_manager AS manager,
        cc.cc_state AS state,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_tickets,
        SUM(ss.ss_net_paid) AS total_sales,
        AVG(ss.ss_net_profit) AS avg_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM call_center cc
    JOIN store_sales ss
        ON ss.ss_sold_date_sk BETWEEN cc.cc_open_date_sk AND COALESCE(cc.cc_closed_date_sk, 9999999)
    WHERE cc.cc_state IN ('CA', 'TX', 'NY')
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_start_date < DATE '2002-01-01'
      AND ss.ss_net_paid > 0
    GROUP BY cc.cc_manager, cc.cc_state
    HAVING SUM(ss.ss_net_paid) > 10000
)
SELECT 
    manager,
    state,
    total_tickets,
    total_sales,
    avg_profit,
    total_quantity,
    RANK() OVER (ORDER BY total_sales DESC) AS revenue_rank
FROM sales_by_cc
ORDER BY total_sales DESC
LIMIT 50
