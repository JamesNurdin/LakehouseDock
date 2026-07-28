WITH overall_stats AS (
    SELECT AVG(sr_net_loss) AS avg_net_loss_all
    FROM store_returns
)
SELECT
    c.c_customer_id,
    ca.ca_state,
    ib.ib_lower_bound,
    t.t_sub_shift,
    r.r_reason_id,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets,
    SUM(sr.sr_net_loss) AS total_store_net_loss,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    CASE
        WHEN SUM(sr.sr_net_loss) > 10000 THEN 'HIGH'
        WHEN SUM(sr.sr_net_loss) > 0    THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_category,
    (SELECT avg_net_loss_all FROM overall_stats) AS overall_avg_loss
FROM
    customer c
    JOIN customer_address ca
        ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
WHERE
    t.t_time BETWEEN 9 AND 18
    AND t.t_sub_shift = 'morning'
    AND r.r_reason_sk = 33
    AND ib.ib_lower_bound >= 30000
    AND c.c_birth_country = 'United States'
    AND c.c_preferred_cust_flag = 'Y'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
          AND wr.wr_returned_time_sk = t.t_time_sk
          AND wr.wr_reason_sk = r.r_reason_sk
          AND wr.wr_return_quantity > 1
    )
GROUP BY
    c.c_customer_id,
    ca.ca_state,
    ib.ib_lower_bound,
    t.t_sub_shift,
    r.r_reason_id
ORDER BY
    total_store_net_loss DESC
LIMIT 100
