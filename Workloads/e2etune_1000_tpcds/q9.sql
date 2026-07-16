WITH store_agg AS (
    SELECT
        t.t_hour,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 6 AND 22
    GROUP BY t.t_hour
),
web_agg AS (
    SELECT
        t.t_hour,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 6 AND 22
    GROUP BY t.t_hour
),
returns_agg AS (
    SELECT
        cc.cc_division,
        t.t_hour,
        SUM(cr.cr_net_loss) AS total_return_loss,
        COUNT(*) AS return_cnt,
        COUNT(DISTINCT r.r_reason_sk) AS distinct_return_reasons,
        SUM(CASE WHEN r.r_reason_desc LIKE '%defect%' THEN cr.cr_return_quantity ELSE 0 END) AS qty_defect_returns
    FROM catalog_returns cr
    JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_city = 'Greenwood'
      AND cc.cc_gmt_offset = -5.00
      AND cp.cp_department = 'Electronics'
      AND t.t_hour BETWEEN 6 AND 22
    GROUP BY cc.cc_division, t.t_hour
    HAVING SUM(cr.cr_net_loss) > 500
)
SELECT
    r.cc_division,
    r.t_hour,
    COALESCE(s.store_net_profit, 0) AS store_net_profit,
    COALESCE(w.web_net_profit, 0) AS web_net_profit,
    r.total_return_loss,
    r.return_cnt,
    r.distinct_return_reasons,
    r.qty_defect_returns
FROM returns_agg r
LEFT JOIN store_agg s ON r.t_hour = s.t_hour
LEFT JOIN web_agg w ON r.t_hour = w.t_hour
ORDER BY r.total_return_loss DESC, r.cc_division, r.t_hour
LIMIT 200
