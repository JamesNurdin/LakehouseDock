WITH eligible_promos AS (
       SELECT p.p_promo_sk
       FROM promotion p
       WHERE p.p_channel_email = 'Y'
       UNION
       SELECT p.p_promo_sk
       FROM promotion p
       WHERE p.p_channel_tv = 'Y'
       EXCEPT
       SELECT p.p_promo_sk
       FROM promotion p
       WHERE p.p_discount_active = 'N'
   ),
   sales_sample AS (
       SELECT cs.cs_order_number,
              cs.cs_sold_date_sk,
              cs.cs_ship_date_sk,
              cs.cs_call_center_sk,
              cs.cs_promo_sk,
              cs.cs_bill_hdemo_sk,
              cs.cs_ship_hdemo_sk,
              cs.cs_item_sk,
              cs.cs_net_profit,
              cs.cs_quantity
       FROM catalog_sales cs
       TABLESAMPLE BERNOULLI (5)
       WHERE cs.cs_net_profit > 0
   ),
   returns AS (
       SELECT sr.sr_ticket_number,
              sr.sr_returned_date_sk,
              sr.sr_hdemo_sk,
              sr.sr_net_loss,
              sr.sr_return_quantity
       FROM store_returns sr
       WHERE sr.sr_net_loss > 0
   )
SELECT
    d_sold.d_year,
    cc.cc_name,
    p.p_promo_name,
    SUM(s.cs_net_profit)                         AS total_profit,
    SUM(r.sr_net_loss)                           AS total_loss,
    COUNT(DISTINCT s.cs_order_number)            AS distinct_orders,
    COUNT(DISTINCT r.sr_ticket_number)           AS distinct_returns
FROM sales_sample s
JOIN date_dim d_sold ON s.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON s.cs_ship_date_sk = d_ship.d_date_sk
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON s.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd_bill ON s.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON s.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
LEFT JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN inventory inv ON inv.inv_date_sk = d_sold.d_date_sk
                         AND inv.inv_item_sk = s.cs_item_sk
JOIN returns r ON r.sr_hdemo_sk = hd_ship.hd_demo_sk
JOIN date_dim d_ret ON r.sr_returned_date_sk = d_ret.d_date_sk
WHERE d_sold.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM eligible_promos ep
        WHERE ep.p_promo_sk = s.cs_promo_sk
  )
GROUP BY d_sold.d_year,
         cc.cc_name,
         p.p_promo_name
HAVING SUM(s.cs_net_profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
