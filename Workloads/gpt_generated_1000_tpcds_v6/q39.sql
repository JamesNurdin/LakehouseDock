WITH store_loss AS (
    SELECT
        s.s_store_name AS store_name,
        hd.hd_buy_potential AS buy_potential,
        SUM(sr.sr_net_loss) AS total_store_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'morning'
      AND hd.hd_buy_potential IN ('1001-5000', '5001-10000')
    GROUP BY s.s_store_name, hd.hd_buy_potential
),
web_loss AS (
    SELECT
        c.c_customer_id AS customer_id,
        hd.hd_buy_potential AS buy_potential,
        SUM(wr.wr_net_loss) AS total_web_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_count
    FROM web_returns wr
    JOIN customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE t.t_sub_shift = 'evening'
      AND hd.hd_buy_potential = '0-500'
    GROUP BY c.c_customer_id, hd.hd_buy_potential
)
SELECT DISTINCT
    combined.channel,
    combined.id,
    combined.buy_potential,
    combined.net_loss,
    combined.return_cnt,
    (SELECT COUNT(*) FROM reason r WHERE r.r_reason_desc = 'Damaged') AS damaged_reason_cnt
FROM (
    SELECT
        'store' AS channel,
        sl.store_name AS id,
        sl.buy_potential,
        sl.total_store_loss AS net_loss,
        sl.store_return_count AS return_cnt
    FROM store_loss sl
    UNION ALL
    SELECT
        'web' AS channel,
        wl.customer_id AS id,
        wl.buy_potential,
        wl.total_web_loss AS net_loss,
        wl.web_return_count AS return_cnt
    FROM web_loss wl
) combined
WHERE EXISTS (SELECT 1 FROM reason r WHERE r.r_reason_desc = 'Damaged')
ORDER BY combined.net_loss DESC
LIMIT 100
