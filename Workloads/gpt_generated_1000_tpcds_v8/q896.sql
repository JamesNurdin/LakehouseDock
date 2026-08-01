WITH base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_net_profit,
       cs.cs_net_paid,
       cs.cs_warehouse_sk,
       cs.cs_sold_time_sk,
       cs.cs_sold_date_sk,
       ws.ws_order_number   AS ws_order_number,
       ws.ws_net_profit      AS ws_net_profit,
       ws.ws_warehouse_sk    AS ws_warehouse_sk,
       wr.wr_net_loss,
       wr.wr_reason_sk,
       sr.sr_net_loss,
       sr.sr_reason_sk,
       t_cs.t_hour,
       w_ws.w_warehouse_name AS w_ws_name,
       r_wr.r_reason_desc    AS wr_reason_desc,
       r_sr.r_reason_desc    AS sr_reason_desc,
       ws_stats.ws_cnt
   FROM catalog_sales cs
   JOIN time_dim t_cs
     ON cs.cs_sold_time_sk = t_cs.t_time_sk
   LEFT JOIN warehouse w_cs
     ON cs.cs_warehouse_sk = w_cs.w_warehouse_sk
   JOIN web_sales ws
     ON ws.ws_sold_time_sk = t_cs.t_time_sk
   JOIN warehouse w_ws
     ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
   JOIN web_returns wr
     ON wr.wr_returned_time_sk = t_cs.t_time_sk
   JOIN reason r_wr
     ON wr.wr_reason_sk = r_wr.r_reason_sk
   JOIN store_returns sr
     ON sr.sr_return_time_sk = t_cs.t_time_sk
   JOIN reason r_sr
     ON sr.sr_reason_sk = r_sr.r_reason_sk
   JOIN time_dim t_extra
     ON wr.wr_returned_time_sk = t_extra.t_time_sk
   CROSS JOIN LATERAL (
       SELECT count(*) AS ws_cnt
       FROM web_sales ws2
       WHERE ws2.ws_warehouse_sk = w_ws.w_warehouse_sk
   ) ws_stats
   WHERE cs.cs_net_profit > 0
)
SELECT
    COALESCE(w_ws_name, 'UNKNOWN')                AS warehouse_name,
    COALESCE(wr_reason_desc, 'UNKNOWN')           AS return_reason_desc,
    t_hour,
    SUM(cs_net_profit)                            AS total_cs_profit,
    SUM(ws_net_profit)                            AS total_ws_profit,
    SUM(wr_net_loss)                              AS total_wr_loss,
    SUM(sr_net_loss)                              AS total_sr_loss,
    COUNT(*)                                      AS transaction_count,
    MAX(ws_cnt)                                   AS ws_cnt,
    (SELECT avg(cs_net_paid) FROM catalog_sales) AS avg_cs_net_paid,
    ROW_NUMBER() OVER (
        PARTITION BY COALESCE(w_ws_name, 'UNKNOWN')
        ORDER BY SUM(cs_net_profit) DESC
    )                                            AS profit_rank
FROM base
GROUP BY GROUPING SETS (
    (w_ws_name, wr_reason_desc),
    (t_hour),
    ()
)
ORDER BY total_cs_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
