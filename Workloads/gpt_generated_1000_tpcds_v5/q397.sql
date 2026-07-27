WITH avg_profit AS (
    SELECT ss_store_sk, AVG(ss_net_profit) AS avg_store_profit
    FROM store_sales
    GROUP BY ss_store_sk
)
SELECT
    ss.ss_store_sk,
    w.w_warehouse_name,
    r.r_reason_desc,
    td.t_shift,
    td.t_meal_time,
    COUNT(*) AS return_cnt,
    SUM(sr.sr_net_loss) AS total_return_loss,
    AVG(sr.sr_return_tax) AS avg_return_tax,
    MIN(sr.sr_return_amt) AS min_return_amt,
    MAX(sr.sr_return_amt) AS max_return_amt,
    ap.avg_store_profit
FROM store_sales ss
JOIN store_returns sr
    ON ss.ss_ticket_number = sr.sr_ticket_number
   AND ss.ss_item_sk = sr.sr_item_sk
JOIN time_dim td
    ON ss.ss_sold_time_sk = td.t_time_sk
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN avg_profit ap
    ON ss.ss_store_sk = ap.ss_store_sk
WHERE td.t_shift = 'first'
  AND td.t_meal_time = 'dinner'
  AND r.r_reason_desc LIKE '%damaged%'
  AND w.w_state = 'CA'
  AND ss.ss_quantity > 5
GROUP BY ss.ss_store_sk, w.w_warehouse_name, r.r_reason_desc, td.t_shift, td.t_meal_time, ap.avg_store_profit
ORDER BY total_return_loss DESC
LIMIT 100
