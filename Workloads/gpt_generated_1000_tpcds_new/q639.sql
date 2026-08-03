WITH store_agg AS (
    SELECT
        r.r_reason_desc,
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt,
        MIN(t.t_hour) AS min_hour,
        MAX(t.t_hour) AS max_hour
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN time_dim t_extra
        ON sr.sr_return_time_sk = t_extra.t_time_sk
    GROUP BY r.r_reason_desc,
        CASE WHEN c.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END
),

web_agg AS (
    SELECT
        r.r_reason_desc,
        CASE WHEN c_ref.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END AS cust_type,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt,
        MIN(t.t_hour) AS min_hour,
        MAX(t.t_hour) AS max_hour
    FROM (
        SELECT
            wr.*,
            ARRAY[wr.wr_return_quantity, CAST(wr.wr_return_amt AS double)] AS qty_amt_arr
        FROM web_returns wr
    ) wr
    CROSS JOIN UNNEST(wr.qty_amt_arr) AS u(val)
    JOIN customer c_ref
        ON wr.wr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer c_ret
        ON wr.wr_returning_customer_sk = c_ret.c_customer_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY r.r_reason_desc,
        CASE WHEN c_ref.c_preferred_cust_flag = 'Y' THEN 'Preferred' ELSE 'Standard' END
),

full_join AS (
    SELECT
        COALESCE(s.r_reason_desc, w.r_reason_desc) AS reason,
        COALESCE(s.cust_type, w.cust_type) AS cust_type,
        COALESCE(s.store_net_loss, 0) AS store_net_loss,
        COALESCE(w.web_net_loss, 0) AS web_net_loss,
        COALESCE(s.store_return_cnt, 0) AS store_return_cnt,
        COALESCE(w.web_return_cnt, 0) AS web_return_cnt,
        COALESCE(s.min_hour, w.min_hour) AS min_hour,
        COALESCE(s.max_hour, w.max_hour) AS max_hour
    FROM store_agg s
    FULL OUTER JOIN web_agg w
        ON s.r_reason_desc = w.r_reason_desc
       AND s.cust_type = w.cust_type
),

union_agg AS (
    SELECT
        s.r_reason_desc AS reason,
        s.cust_type,
        s.store_net_loss AS net_loss,
        s.store_return_cnt AS return_cnt,
        s.min_hour,
        s.max_hour,
        'store' AS src
    FROM store_agg s
    UNION DISTINCT
    SELECT
        w.r_reason_desc AS reason,
        w.cust_type,
        w.web_net_loss AS net_loss,
        w.web_return_cnt AS return_cnt,
        w.min_hour,
        w.max_hour,
        'web' AS src
    FROM web_agg w
),

final AS (
    SELECT
        ua.reason,
        ua.cust_type,
        SUM(ua.net_loss) AS total_net_loss,
        SUM(ua.return_cnt) AS total_returns,
        MIN(ua.min_hour) AS overall_min_hour,
        MAX(ua.max_hour) AS overall_max_hour,
        COUNT(DISTINCT ua.src) AS sources_count
    FROM union_agg ua
    GROUP BY ua.reason, ua.cust_type
)

SELECT *
FROM final
ORDER BY total_net_loss DESC, reason
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
