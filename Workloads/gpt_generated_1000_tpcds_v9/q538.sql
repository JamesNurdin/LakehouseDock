WITH cs_data AS (
    SELECT
        cs.cs_order_number AS order_id,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        i1.i_category AS category,
        t1.t_hour AS hour,
        'catalog' AS channel
    FROM catalog_sales cs
    INNER JOIN item i1
        ON cs.cs_item_sk = i1.i_item_sk
    INNER JOIN time_dim t1
        ON cs.cs_sold_time_sk = t1.t_time_sk
    WHERE i1.i_category = 'Electronics'
),
sr_data AS (
    SELECT
        sr.sr_ticket_number AS order_id,
        -sr.sr_return_amt AS net_paid,
        -sr.sr_net_loss AS net_profit,
        i2.i_category AS category,
        t2.t_hour AS hour,
        'store_return' AS channel
    FROM store_returns sr
    INNER JOIN item i2
        ON sr.sr_item_sk = i2.i_item_sk
    INNER JOIN time_dim t2
        ON sr.sr_return_time_sk = t2.t_time_sk
    INNER JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE i2.i_category = 'Electronics'
      AND r.r_reason_desc LIKE '%size%'
),
ws_data AS (
    SELECT
        ws.ws_order_number AS order_id,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        i3.i_category AS category,
        t3.t_hour AS hour,
        'web' AS channel
    FROM web_sales ws
    INNER JOIN item i3
        ON ws.ws_item_sk = i3.i_item_sk
    INNER JOIN time_dim t3
        ON ws.ws_sold_time_sk = t3.t_time_sk
    INNER JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE i3.i_category = 'Electronics'
      AND ws.ws_wholesale_cost > 30
)
SELECT
    channel,
    category,
    hour,
    SUM(net_paid) AS total_net_paid,
    SUM(net_profit) AS total_net_profit,
    COUNT(*) AS txn_count
FROM (
    SELECT order_id, net_paid, net_profit, category, hour, channel FROM cs_data
    UNION ALL
    SELECT order_id, net_paid, net_profit, category, hour, channel FROM sr_data
    UNION ALL
    SELECT order_id, net_paid, net_profit, category, hour, channel FROM ws_data
) combined
GROUP BY ROLLUP (channel, category, hour)
ORDER BY channel, category, hour
