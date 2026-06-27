WITH
    store_agg AS (
        SELECT
            td.t_time_sk,
            td.t_hour,
            td.t_shift,
            SUM(ss.ss_net_paid) AS store_net_paid,
            SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        GROUP BY td.t_time_sk, td.t_hour, td.t_shift
    ),
    web_agg AS (
        SELECT
            td.t_time_sk,
            td.t_hour,
            td.t_shift,
            SUM(ws.ws_net_paid) AS web_net_paid,
            SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        GROUP BY td.t_time_sk, td.t_hour, td.t_shift
    ),
    return_agg AS (
        SELECT
            td.t_time_sk,
            td.t_hour,
            td.t_shift,
            SUM(cr.cr_net_loss) AS total_net_loss,
            SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        GROUP BY td.t_time_sk, td.t_hour, td.t_shift
    )
SELECT
    COALESCE(s.t_hour, w.t_hour, r.t_hour) AS hour_of_day,
    COALESCE(s.t_shift, w.t_shift, r.t_shift) AS shift,
    s.store_net_paid,
    w.web_net_paid,
    r.total_net_loss,
    (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0) - COALESCE(r.total_net_loss, 0)) AS overall_profit
FROM store_agg s
FULL OUTER JOIN web_agg w ON s.t_time_sk = w.t_time_sk
FULL OUTER JOIN return_agg r ON COALESCE(s.t_time_sk, w.t_time_sk) = r.t_time_sk
ORDER BY hour_of_day, shift
