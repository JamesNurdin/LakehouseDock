WITH agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        cp.cp_department,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM date_dim d
    JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'TX'
      AND cp.cp_department = 'DEPARTMENT'
      AND cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
    GROUP BY s.s_store_id, s.s_store_name, cp.cp_department
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.cp_department,
    a.total_net_profit,
    a.total_return_amount,
    CASE WHEN a.total_return_amount > a.total_net_profit THEN 'Loss' ELSE 'Gain' END AS performance,
    RANK() OVER (PARTITION BY a.cp_department ORDER BY a.total_net_profit DESC) AS profit_rank
FROM agg a
ORDER BY a.cp_department, profit_rank
LIMIT 100
