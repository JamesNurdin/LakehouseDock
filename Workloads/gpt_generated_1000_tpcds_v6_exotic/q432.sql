WITH agg AS (
    SELECT
        d.d_year AS d_year,
        w.w_state AS w_state,
        SUM(ss.ss_net_profit) AS total_profit,
        AVG(ss.ss_quantity) AS avg_quantity,
        SUM(CASE WHEN sr.sr_return_amt > 0 THEN sr.sr_return_amt ELSE 0 END) AS total_return_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = ss.ss_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
      AND cc.cc_division_name = 'anti'
      AND w.w_warehouse_sq_ft > 500000
    GROUP BY ROLLUP (d.d_year, w.w_state)
    HAVING SUM(ss.ss_net_profit) > 10000
)
SELECT
    d_year,
    w_state,
    CASE WHEN total_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
    total_profit,
    avg_quantity,
    total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY d_year, w_state
LIMIT 100
