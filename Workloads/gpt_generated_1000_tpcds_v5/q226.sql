WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_state,
        td.t_sub_shift,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    WHERE s.s_state = 'CA'
      AND td.t_sub_shift = 'morning'
      AND ss.ss_net_paid > 1000
      AND sr.sr_reversed_charge > 10
    GROUP BY s.s_store_id, s.s_state, td.t_sub_shift
    HAVING SUM(ss.ss_net_paid) > 5000
       AND SUM(sr.sr_net_loss) > 0
)
SELECT
    sa.s_store_id,
    sa.s_state,
    sa.t_sub_shift,
    sa.total_sales,
    sa.total_profit,
    sa.total_return_loss,
    sa.total_web_return_loss,
    CASE
        WHEN sa.total_sales > (SELECT avg(ss2.ss_net_paid) FROM store_sales ss2) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_compared_to_avg,
    RANK() OVER (PARTITION BY sa.s_state ORDER BY sa.total_sales DESC) AS sales_rank_state
FROM sales_agg sa
ORDER BY sa.s_state, sales_rank_state
