WITH returns_agg AS (
    SELECT
        cc.cc_call_center_id,
        cc.cc_company_name,
        d_ret.d_year,
        d_ret.d_month_seq,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        AVG(wr.wr_return_ship_cost) AS avg_ship_cost,
        CASE
            WHEN SUM(wr.wr_net_loss) > 10000 THEN 'HIGH'
            WHEN SUM(wr.wr_net_loss) > 0    THEN 'MEDIUM'
            ELSE 'LOW'
        END AS loss_category
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer c_refund
        ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer c_return
        ON wr.wr_returning_customer_sk = c_return.c_customer_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_ret.d_date_sk
    JOIN date_dim d_cc
        ON cc.cc_open_date_sk = d_cc.d_date_sk
    WHERE d_ret.d_moy IN (1, 5, 10)                     -- month filter
      AND d_ret.d_holiday = 'N'                        -- non‑holiday filter
      AND cc.cc_company_name LIKE '%able%'            -- company name pattern
      AND wr.wr_return_ship_cost > 100                -- ship cost filter
      AND t.t_hour BETWEEN 9 AND 17                   -- business‑hour filter
    GROUP BY
        cc.cc_call_center_id,
        cc.cc_company_name,
        d_ret.d_year,
        d_ret.d_month_seq
)
SELECT
    r.cc_call_center_id,
    r.cc_company_name,
    r.d_year,
    r.d_month_seq,
    r.total_net_loss,
    r.return_cnt,
    r.loss_category,
    CASE
        WHEN r.total_net_loss > (SELECT MAX(total_net_loss) FROM returns_agg) THEN 'MAX_LOSS'
        ELSE 'NORMAL'
    END AS loss_flag
FROM returns_agg r
WHERE r.return_cnt >= 10
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
        WHERE d2.d_year = r.d_year
          AND wr2.wr_net_loss > 0
          AND wr2.wr_refunded_customer_sk = (
                SELECT c.c_customer_sk
                FROM customer c
                WHERE c.c_email_address LIKE '%@example.com%'
                LIMIT 1
          )
  )
ORDER BY r.total_net_loss DESC
LIMIT 100
