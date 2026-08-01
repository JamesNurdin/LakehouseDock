WITH distinct_reason AS (
    SELECT DISTINCT r_reason_sk, r_reason_desc
    FROM reason
    WHERE r_reason_desc LIKE '%time%'
),
base AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_net_loss,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ext_discount_amt,
        td.t_hour,
        s.s_state,
        w.w_state,
        w.w_city,
        i.inv_quantity_on_hand,
        cd.cd_credit_rating
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN distinct_reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_sales ws ON td.t_time_sk = ws.ws_sold_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE s.s_state = 'CA'
      AND w.w_city = 'Spring'
      AND td.t_hour BETWEEN 8 AND 18
      AND ws.ws_ext_discount_amt > 1000
      AND i.inv_quantity_on_hand > 0
)
SELECT
    region,
    hour,
    metric_type,
    SUM(metric_amount) AS total_amount,
    SUM(net_metric) AS total_net,
    SUM(txn_count) AS total_txn,
    SUM(distinct_credit_ratings) AS total_distinct_credit_ratings
FROM (
    SELECT
        s_state AS region,
        t_hour AS hour,
        'Return' AS metric_type,
        SUM(sr_return_amt) AS metric_amount,
        SUM(sr_net_loss) AS net_metric,
        COUNT(*) AS txn_count,
        COUNT(DISTINCT cd_credit_rating) AS distinct_credit_ratings
    FROM base
    GROUP BY s_state, t_hour
    UNION ALL
    SELECT
        w_state AS region,
        t_hour AS hour,
        'Sale' AS metric_type,
        SUM(ws_ext_sales_price) AS metric_amount,
        SUM(ws_net_profit) AS net_metric,
        COUNT(*) AS txn_count,
        COUNT(DISTINCT cd_credit_rating) AS distinct_credit_ratings
    FROM base
    GROUP BY w_state, t_hour
) combined
GROUP BY ROLLUP (region, hour, metric_type)
ORDER BY region, hour, metric_type
LIMIT 100
