WITH base AS (
   SELECT
      s.s_state,
      s.s_gmt_offset,
      t.t_hour,
      hd.hd_buy_potential,
      hd.hd_vehicle_count,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      ss.ss_ticket_number,
      ss.ss_quantity,
      ss.ss_net_paid,
      ss.ss_net_profit,
      sr.sr_return_quantity,
      sr.sr_net_loss AS store_return_loss,
      wr.wr_return_quantity,
      wr.wr_net_loss AS web_return_loss,
      wp.wp_type
   FROM store_sales ss
   JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
   JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
   JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
   LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_store_sk = sr.sr_store_sk
        AND ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_hdemo_sk = sr.sr_hdemo_sk
   LEFT JOIN web_returns wr
        ON wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   LEFT JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
   WHERE hd.hd_buy_potential = '1001-5000'
     AND hd.hd_vehicle_count >= 2
     AND s.s_state = 'CA'
     AND s.s_gmt_offset BETWEEN -8.00 AND -7.00
     AND ib.ib_lower_bound >= 25000
     AND t.t_hour BETWEEN 9 AND 17
     AND wp.wp_type = 'article'
)
SELECT
   s_state,
   t_hour,
   hd_buy_potential,
   COUNT(DISTINCT ss_ticket_number) AS num_transactions,
   SUM(ss_quantity) AS total_quantity_sold,
   SUM(ss_net_paid) AS total_net_paid,
   SUM(ss_net_profit) AS total_net_profit,
   SUM(COALESCE(store_return_loss, 0)) AS total_store_return_loss,
   SUM(COALESCE(web_return_loss, 0)) AS total_web_return_loss,
   AVG(hd_vehicle_count) AS avg_vehicle_count,
   MIN(ib_lower_bound) AS min_income_lower,
   MAX(ib_upper_bound) AS max_income_upper
FROM base
GROUP BY
   s_state,
   t_hour,
   hd_buy_potential
HAVING
   SUM(ss_net_profit) > 10000
   AND COUNT(DISTINCT ss_ticket_number) >= 50
ORDER BY
   total_net_profit DESC,
   s_state,
   t_hour
LIMIT 100
