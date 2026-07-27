WITH sales_summary AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        s.s_state,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        AVG(ss.ss_net_profit) AS avg_profit
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE s.s_state = 'CA'
      AND s.s_tax_percentage > 0.05
      AND td.t_hour BETWEEN 9 AND 17
    GROUP BY ss.ss_store_sk, s.s_store_name, s.s_state
    HAVING SUM(ss.ss_net_profit) > 1000
)
SELECT
    ss_sum.s_store_name,
    ss_sum.s_state,
    ss_sum.total_profit,
    ss_sum.sales_cnt,
    cr.cr_return_amount,
    wr.wr_return_ship_cost,
    sr.sr_return_amt,
    EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_store_sk = ss_sum.ss_store_sk
          AND sr2.sr_return_quantity > 5
    ) AS has_large_return
FROM sales_summary ss_sum
JOIN store_sales ss
    ON ss.ss_store_sk = ss_sum.ss_store_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = ss.ss_sold_time_sk
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = ss.ss_sold_time_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN store_returns sr
    ON sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
WHERE cr.cr_return_amount > 50
  AND wr.wr_return_ship_cost < 500
  AND sr.sr_return_quantity > 2
  AND r_cr.r_reason_desc LIKE '%damaged%'
  AND r_wr.r_reason_desc LIKE '%customer%'
ORDER BY ss_sum.total_profit DESC
LIMIT 100
