WITH
    store_base AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_sold_date_sk,
            ts.t_hour,
            cd_sales.cd_gender,
            ss.ss_quantity,
            ss.ss_net_paid,
            ss.ss_net_profit,
            sr.sr_return_amt,
            r.r_reason_desc
        FROM store_sales ss
        JOIN time_dim ts ON ss.ss_sold_time_sk = ts.t_time_sk
        JOIN customer_demographics cd_sales ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk
        LEFT JOIN store_returns sr
            ON ss.ss_ticket_number = sr.sr_ticket_number
            AND ss.ss_item_sk = sr.sr_item_sk
        LEFT JOIN time_dim tr ON sr.sr_return_time_sk = tr.t_time_sk
        LEFT JOIN customer_demographics cd_return ON sr.sr_cdemo_sk = cd_return.cd_demo_sk
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    ),
    store_agg AS (
        SELECT
            'store' AS channel,
            ss_sold_date_sk AS date_sk,
            t_hour AS hour,
            cd_gender AS gender,
            SUM(ss_quantity) AS total_quantity,
            SUM(ss_net_paid) AS total_net_paid,
            SUM(ss_net_profit) AS total_net_profit,
            SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt,
            MAX(r_reason_desc) AS return_reason
        FROM store_base
        GROUP BY ss_sold_date_sk, t_hour, cd_gender
    ),
    web_base AS (
        SELECT
            ws.ws_order_number,
            ws.ws_sold_date_sk,
            tw.t_hour,
            cd_bill.cd_gender AS bill_gender,
            cd_ship.cd_gender AS ship_gender,
            ws.ws_quantity,
            ws.ws_net_paid,
            ws.ws_net_profit
        FROM web_sales ws
        JOIN time_dim tw ON ws.ws_sold_time_sk = tw.t_time_sk
        JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
    ),
    web_agg AS (
        SELECT
            'web' AS channel,
            ws_sold_date_sk AS date_sk,
            t_hour AS hour,
            bill_gender AS gender,
            SUM(ws_quantity) AS total_quantity,
            SUM(ws_net_paid) AS total_net_paid,
            SUM(ws_net_profit) AS total_net_profit,
            CAST(0 AS decimal(7,2)) AS total_return_amt,
            CAST(NULL AS varchar) AS return_reason
        FROM web_base
        GROUP BY ws_sold_date_sk, t_hour, bill_gender
    ),
    union_all_data AS (
        SELECT * FROM store_agg
        UNION ALL
        SELECT * FROM web_agg
    ),
    final AS (
        SELECT
            channel,
            date_sk,
            hour,
            gender,
            total_quantity,
            total_net_paid,
            total_net_profit,
            total_return_amt,
            return_reason,
            SUM(total_net_paid) OVER (PARTITION BY channel ORDER BY date_sk, hour ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_paid,
            RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
        FROM union_all_data
    )
SELECT
    channel,
    date_sk,
    hour,
    gender,
    total_quantity,
    total_net_paid,
    total_net_profit,
    total_return_amt,
    return_reason,
    cumulative_net_paid,
    net_paid_rank
FROM final
ORDER BY net_paid_rank
LIMIT 100
