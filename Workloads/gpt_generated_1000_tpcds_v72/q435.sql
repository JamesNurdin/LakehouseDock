WITH fact_join AS (
   SELECT
       cr.cr_returned_time_sk,
       cr.cr_returned_date_sk,
       cr.cr_item_sk,
       cr.cr_return_amount,
       cr.cr_net_loss,
       cr.cr_refunded_addr_sk,
       cr.cr_returning_addr_sk,
       cr.cr_refunded_hdemo_sk,
       cr.cr_returning_hdemo_sk,
       cr.cr_ship_mode_sk,
       cr.cr_reason_sk,
       sr.sr_return_time_sk,
       sr.sr_return_amt,
       sr.sr_net_loss,
       sr.sr_addr_sk,
       sr.sr_hdemo_sk,
       sr.sr_reason_sk,
       ws.ws_sold_time_sk,
       ws.ws_net_paid,
       ws.ws_net_profit,
       ws.ws_web_site_sk,
       ws.ws_ship_mode_sk,
       ws.ws_bill_addr_sk,
       ws.ws_bill_hdemo_sk,
       ws.ws_ship_addr_sk,
       ws.ws_ship_hdemo_sk,
       i.i_category,
       i.i_brand,
       i.i_current_price
   FROM catalog_returns cr
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk                           -- allowed rule
   JOIN store_returns sr
     ON sr.sr_item_sk = i.i_item_sk                           -- allowed rule
   JOIN web_sales ws
     ON ws.ws_item_sk = i.i_item_sk                           -- allowed rule
   WHERE EXISTS (
       SELECT 1
       FROM inventory inv
       WHERE inv.inv_item_sk = cr.cr_item_sk
         AND inv.inv_quantity_on_hand > 0
   )
     AND cr.cr_return_amount > 0                               -- predicate 1
     AND sr.sr_return_amt > 0                                 -- predicate 2
     AND ws.ws_net_profit > 0                                 -- predicate 3
     AND cr.cr_returned_time_sk BETWEEN 1000 AND 2000        -- predicate 4
     AND sr.sr_return_time_sk BETWEEN 1000 AND 2000          -- predicate 5
     AND ws.ws_sold_time_sk BETWEEN 1000 AND 2000            -- predicate 6
),
agg AS (
   SELECT
       ws_site.web_site_id,
       ws_site.web_name,
       i_category,
       i_brand,
       t_cr.t_shift,
       SUM(fj.cr_return_amount)            AS total_return_amount,
       SUM(fj.sr_return_amt)               AS total_store_return,
       SUM(fj.ws_net_profit)               AS total_net_profit,
       COUNT(DISTINCT fj.cr_item_sk)       AS distinct_items
   FROM fact_join fj
   /* dimension joins */
   JOIN time_dim t_cr
     ON fj.cr_returned_time_sk = t_cr.t_time_sk               -- allowed rule
   JOIN time_dim t_sr
     ON fj.sr_return_time_sk = t_sr.t_time_sk                 -- allowed rule
   JOIN time_dim t_ws
     ON fj.ws_sold_time_sk = t_ws.t_time_sk                    -- allowed rule
   JOIN ship_mode sm_cr
     ON fj.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk            -- allowed rule
   JOIN ship_mode sm_ws
     ON fj.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk            -- allowed rule
   JOIN reason r_cr
     ON fj.cr_reason_sk = r_cr.r_reason_sk                    -- allowed rule
   JOIN reason r_sr
     ON fj.sr_reason_sk = r_sr.r_reason_sk                    -- allowed rule
   JOIN customer_address ca_ref
     ON fj.cr_refunded_addr_sk = ca_ref.ca_address_sk        -- allowed rule
   JOIN household_demographics hd_ref
     ON fj.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk          -- allowed rule
   JOIN income_band ib
     ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk      -- allowed rule
   JOIN web_site ws_site
     ON fj.ws_web_site_sk = ws_site.web_site_sk              -- allowed rule
   WHERE t_cr.t_second BETWEEN 0 AND 30                      -- predicate 7
     AND t_sr.t_minute IN (0,15,30,45)                       -- predicate 8
     AND ws_site.web_state = 'CA'                            -- predicate 9
     AND fj.i_current_price BETWEEN 10 AND 1000              -- predicate 10
     AND ib.ib_upper_bound > 50000                           -- predicate 11
   GROUP BY
       ws_site.web_site_id,
       ws_site.web_name,
       i_category,
       i_brand,
       t_cr.t_shift
   HAVING COUNT(DISTINCT fj.cr_item_sk) > 5                 -- predicate 12
)
SELECT
   web_site_id,
   web_name,
   i_category,
   i_brand,
   t_shift,
   total_return_amount,
   total_store_return,
   total_net_profit,
   CASE
       WHEN total_net_profit > 100000 THEN 'HIGH'
       WHEN total_net_profit > 50000  THEN 'MEDIUM'
       ELSE 'LOW'
   END AS profit_category,
   RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank, web_site_id
LIMIT 100
