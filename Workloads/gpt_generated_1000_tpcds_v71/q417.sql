WITH base AS (
   SELECT
       s.s_store_id,
       s.s_state,
       t.t_hour,
       SUM(ss.ss_ext_sales_price)                     AS store_sales_amount,
       SUM(ss.ss_ext_discount_amt)                    AS store_discount_amount,
       SUM(ss.ss_net_profit)                          AS store_net_profit,
       SUM(COALESCE(sr.sr_refunded_cash, 0))          AS total_refunded_cash,
       SUM(COALESCE(sr.sr_net_loss, 0))               AS total_net_loss,
       SUM(ws.ws_ext_sales_price)                     AS web_sales_amount,
       SUM(ws.ws_ext_discount_amt)                    AS web_discount_amount
   FROM tpcds.store s
   JOIN tpcds.store_sales ss
       ON s.s_store_sk = ss.ss_store_sk
   JOIN tpcds.time_dim t
       ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN tpcds.store_returns sr
       ON sr.sr_store_sk = s.s_store_sk
      AND sr.sr_ticket_number = ss.ss_ticket_number
      AND sr.sr_return_time_sk = t.t_time_sk
   JOIN tpcds.web_sales ws
       ON ws.ws_sold_time_sk = t.t_time_sk
   WHERE s.s_state = 'CA'
     AND t.t_hour BETWEEN 9 AND 17
     AND ss.ss_ext_sales_price > 1000
     AND ws.ws_net_paid_inc_tax > 500
     AND ws.ws_ext_ship_cost < 200
     AND (sr.sr_net_loss IS NULL OR sr.sr_net_loss > 0)
   GROUP BY s.s_store_id, s.s_state, t.t_hour
),
ranked AS (
   SELECT
       b.*,                                                   
       ROW_NUMBER() OVER (PARTITION BY b.s_state ORDER BY b.store_net_profit DESC) AS profit_rank_state,
       (b.store_sales_amount - b.total_refunded_cash)          AS net_sales_after_returns,
       (b.store_sales_amount + b.web_sales_amount)            AS combined_sales
   FROM base b
)
SELECT
   r.s_state,
   r.s_store_id,
   r.t_hour,
   r.store_sales_amount,
   r.web_sales_amount,
   r.net_sales_after_returns,
   r.combined_sales,
   r.profit_rank_state,
   AVG(r.combined_sales) OVER (PARTITION BY r.s_state)       AS avg_combined_sales_state
FROM ranked r
WHERE r.profit_rank_state <= 3
ORDER BY r.s_state, r.profit_rank_state
