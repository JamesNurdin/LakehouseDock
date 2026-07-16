WITH store_agg AS (
    SELECT ss.ss_sold_date_sk AS date_sk,
           ss.ss_sold_time_sk AS time_sk,
           SUM(ss.ss_net_profit) AS store_net_profit,
           SUM(ss.ss_ext_sales_price) AS store_sales_amount,
           COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    WHERE ss.ss_net_profit IS NOT NULL
    GROUP BY ss.ss_sold_date_sk, ss.ss_sold_time_sk
),
web_agg AS (
    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_sold_time_sk AS time_sk,
           SUM(ws.ws_net_profit) AS web_net_profit,
           SUM(ws.ws_ext_sales_price) AS web_sales_amount,
           COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
    GROUP BY ws.ws_sold_date_sk, ws.ws_sold_time_sk
),
return_agg AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_returned_time_sk AS time_sk,
           cr.cr_call_center_sk AS call_center_sk,
           SUM(cr.cr_net_loss) AS return_net_loss,
           SUM(cr.cr_return_amount) AS return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_net_loss IS NOT NULL
    GROUP BY cr.cr_returned_date_sk, cr.cr_returned_time_sk, cr.cr_call_center_sk
)
SELECT d.d_year,
       d.d_month_seq,
       cc.cc_name,
       COALESCE(sa.store_net_profit, 0) + COALESCE(wa.web_net_profit, 0) - COALESCE(ra.return_net_loss, 0) AS total_net_profit,
       COALESCE(sa.store_sales_amount, 0) + COALESCE(wa.web_sales_amount, 0) AS total_sales_amount,
       COALESCE(sa.store_txn_cnt, 0) + COALESCE(wa.web_txn_cnt, 0) AS total_txn_cnt,
       COALESCE(ra.return_cnt, 0) AS total_returns
FROM return_agg ra
JOIN call_center cc ON ra.call_center_sk = cc.cc_call_center_sk
JOIN date_dim d ON ra.date_sk = d.d_date_sk
JOIN time_dim t ON ra.time_sk = t.t_time_sk
LEFT JOIN store_agg sa ON ra.date_sk = sa.date_sk AND ra.time_sk = sa.time_sk
LEFT JOIN web_agg wa ON ra.date_sk = wa.date_sk AND ra.time_sk = wa.time_sk
WHERE d.d_year BETWEEN 2000 AND 2001
  AND cc.cc_city = 'Greenwood'
  AND cc.cc_manager = 'Bob Belcher'
  AND t.t_hour BETWEEN 9 AND 17
ORDER BY total_net_profit DESC
LIMIT 100
