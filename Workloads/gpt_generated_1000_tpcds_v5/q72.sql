WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_time_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451400 AND 2451600
    GROUP BY ss_store_sk, ss_sold_time_sk
)
SELECT
    s.s_store_id,
    td.t_hour,
    ss_agg.total_net_paid,
    ss_agg.total_quantity,
    sr.sr_return_amt AS total_return_amt,
    wr.wr_fee,
    ws.ws_web_page_sk,
    ws.ws_quantity,
    RANK() OVER (PARTITION BY td.t_hour ORDER BY ss_agg.total_net_paid DESC) AS store_hour_rank,
    CASE WHEN ss_agg.total_net_paid > 5000 THEN 'HIGH' ELSE 'LOW' END AS sales_level
FROM ss_agg
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN time_dim td
    ON ss_agg.ss_sold_time_sk = td.t_time_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_return_time_sk = td.t_time_sk
JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_time_sk = td.t_time_sk
   AND wr.wr_order_number = ws.ws_order_number
WHERE
    ws.ws_quantity > 50
    AND wr.wr_fee > 30
    AND s.s_state = 'CA'
ORDER BY td.t_hour, store_hour_rank
LIMIT 100
