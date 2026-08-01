WITH sales_returns_summary AS (
    SELECT
        s.s_store_sk,
        s.s_store_name AS store_name,
        s.s_state AS state,
        r.r_reason_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_sales_transactions,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_return_transactions
    FROM
        store_sales ss
        INNER JOIN customer_demographics cd
            ON ss.ss_cdemo_sk = cd.cd_demo_sk
        INNER JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        INNER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        INNER JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        LEFT OUTER JOIN reason r
            ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        cd.cd_purchase_estimate >= 5000
        AND cd.cd_dep_employed_count >= 2
        AND hd.hd_vehicle_count >= 1
        AND ss.ss_ext_sales_price > 1000
        AND ss.ss_coupon_amt > 200
        AND s.s_state = 'CA'
        AND (r.r_reason_id IS NULL OR r.r_reason_id = 'AAAAAAAAFAAAAAAA')
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        r.r_reason_desc
)
SELECT
    store_name,
    state,
    AVG(total_net_loss) AS avg_net_loss,
    SUM(total_sales_price) AS sum_sales_price,
    SUM(total_net_profit) AS sum_net_profit,
    SUM(num_sales_transactions) AS total_sales_transactions,
    SUM(num_return_transactions) AS total_return_transactions
FROM
    sales_returns_summary
GROUP BY
    store_name,
    state
HAVING
    AVG(total_net_loss) > 5000
ORDER BY
    avg_net_loss DESC
LIMIT 100
