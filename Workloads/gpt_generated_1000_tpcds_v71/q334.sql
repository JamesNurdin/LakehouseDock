WITH distinct_cc AS (
        SELECT DISTINCT cc_call_center_sk,
                        cc_call_center_id,
                        cc_city,
                        cc_state
        FROM call_center
        WHERE cc_state = 'CA'
    ),
    base_sales AS (
        SELECT ss.ss_ticket_number,
               ss.ss_sold_time_sk,
               ss.ss_item_sk,
               ss.ss_customer_sk,
               ss.ss_hdemo_sk,
               ss.ss_addr_sk,
               ss.ss_store_sk,
               ss.ss_promo_sk,
               ss.ss_quantity,
               ss.ss_net_paid,
               ss.ss_net_profit,
               p.p_promo_name,
               p.p_channel_email,
               p.p_discount_active,
               hd.hd_income_band_sk,
               hd.hd_buy_potential,
               ca.ca_state,
               ca.ca_city,
               t.t_shift,
               t.t_meal_time
        FROM store_sales ss
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        WHERE p.p_discount_active = 'Y'
          AND ca.ca_state = 'CA'
          AND t.t_shift = 'first'
          AND hd.hd_income_band_sk BETWEEN 5 AND 10
    )
SELECT dc.cc_call_center_id,
       dc.cc_city,
       cp.cp_department,
       w.w_warehouse_name,
       SUM(cr.cr_return_amount)               AS total_return_amount,
       SUM(wr.wr_return_amt)                 AS total_web_return_amount,
       SUM(bs.ss_net_profit)                 AS total_net_profit,
       AVG(bs.ss_net_paid)                   AS avg_net_paid,
       COUNT(DISTINCT bs.ss_ticket_number)   AS distinct_tickets,
       CASE WHEN SUM(bs.ss_net_profit) > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_flag,
       ROW_NUMBER() OVER (PARTITION BY dc.cc_call_center_id ORDER BY SUM(bs.ss_net_profit) DESC) AS rn
FROM base_sales bs
JOIN catalog_returns cr ON cr.cr_returned_time_sk = bs.ss_sold_time_sk
JOIN web_returns wr    ON wr.wr_returned_time_sk = bs.ss_sold_time_sk
JOIN distinct_cc dc    ON cr.cr_call_center_sk = dc.cc_call_center_sk
JOIN catalog_page cp   ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w       ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE cp.cp_type = 'A'
  AND w.w_state = 'CA'
  AND cr.cr_return_quantity > 0
GROUP BY dc.cc_call_center_id,
         dc.cc_city,
         cp.cp_department,
         w.w_warehouse_name
ORDER BY total_net_profit DESC
LIMIT 100
