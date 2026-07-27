WITH store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        cd.cd_credit_rating,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(sr.sr_net_loss) AS total_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_transactions,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_transactions
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE cd.cd_credit_rating IN ('Good', 'High Risk')
      AND cd.cd_dep_college_count >= 3
      AND s.s_number_employees BETWEEN 200 AND 300
      AND r.r_reason_desc NOT LIKE '%damaged%'
      AND td.t_hour BETWEEN 9 AND 17
      AND c.c_last_name LIKE 'S%'
      AND s.s_manager = 'Robert Thompson'
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name, cd.cd_credit_rating
),
avg_profit_by_rating AS (
    SELECT
        cd_credit_rating,
        AVG(total_sales - total_return_loss) AS avg_net_profit
    FROM store_agg
    GROUP BY cd_credit_rating
)
SELECT
    sa.s_store_id,
    sa.s_store_name,
    sa.cd_credit_rating,
    sa.total_sales,
    sa.total_return_loss,
    (sa.total_sales - sa.total_return_loss) AS net_profit,
    ap.avg_net_profit,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_store_sk = sa.s_store_sk) AS total_returns_for_store
FROM store_agg sa
JOIN avg_profit_by_rating ap
    ON sa.cd_credit_rating = ap.cd_credit_rating
WHERE (sa.total_sales - sa.total_return_loss) > ap.avg_net_profit
  AND sa.sales_transactions >= 5
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        JOIN reason r3 ON sr3.sr_reason_sk = r3.r_reason_sk
        WHERE sr3.sr_store_sk = sa.s_store_sk
          AND r3.r_reason_desc LIKE '%Customer%'
    )
ORDER BY net_profit DESC
LIMIT 100
