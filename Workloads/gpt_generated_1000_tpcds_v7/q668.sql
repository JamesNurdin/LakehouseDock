WITH store_perf AS (
    SELECT
        s.s_store_id,
        td.t_sub_shift,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(wr.wr_net_loss) AS total_loss,
        COUNT(ss.ss_ticket_number) AS sales_count
    FROM store s
    JOIN store_sales ss
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE s.s_city IN ('Cedar Grove', 'Glendale')
      AND s.s_number_employees >= 220
      AND ss.ss_list_price > 20
      AND ss.ss_ext_tax < 10
      AND td.t_sub_shift = 'afternoon'
      AND wr.wr_return_quantity > 0
    GROUP BY s.s_store_id, td.t_sub_shift
)
SELECT
    t_sub_shift,
    AVG(total_profit) AS avg_total_profit,
    AVG(total_loss) AS avg_total_loss,
    SUM(sales_count) AS total_sales_transactions
FROM store_perf
GROUP BY t_sub_shift
HAVING AVG(total_profit) > 500
ORDER BY avg_total_profit DESC
LIMIT 100
