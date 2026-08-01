WITH high_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        i.i_category,
        inv.inv_quantity_on_hand
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_current_price > 100
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    s.s_store_id,
    hi.i_item_id,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(sr.sr_refunded_cash) AS total_return_amount,
    SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss) AS net_profit_loss,
    AVG(hi.i_current_price) AS avg_item_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_txns
FROM store_sales ss
JOIN high_inventory hi ON ss.ss_item_sk = hi.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                       AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE hd.hd_dep_count = 3
  AND hd.hd_vehicle_count = 2
  AND s.s_state = 'CA'
  AND ib.ib_lower_bound >= 50000
  AND r.r_reason_desc = 'Damaged'
  AND ss.ss_ext_sales_price > 100
GROUP BY s.s_store_id, hi.i_item_id

UNION

SELECT
    s.s_store_id,
    hi.i_item_id,
    SUM(ss.ss_ext_sales_price) AS total_sales_amount,
    SUM(sr.sr_refunded_cash) AS total_return_amount,
    SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss) AS net_profit_loss,
    AVG(hi.i_current_price) AS avg_item_price,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_txns
FROM store_sales ss
JOIN high_inventory hi ON ss.ss_item_sk = hi.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                       AND sr.sr_item_sk = ss.ss_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE hd.hd_dep_count = 6
  AND hd.hd_vehicle_count = 1
  AND s.s_state = 'TX'
  AND ib.ib_upper_bound <= (
        SELECT MAX(ib2.ib_upper_bound)
        FROM income_band ib2
        WHERE ib2.ib_lower_bound >= 50000
    )
  AND r.r_reason_desc = 'Defective'
  AND ss.ss_ext_sales_price > 200
GROUP BY s.s_store_id, hi.i_item_id
ORDER BY total_sales_amount DESC
LIMIT 100
