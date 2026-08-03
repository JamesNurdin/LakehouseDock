WITH sampled_inv AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (5)
    WHERE inv_quantity_on_hand > 0
)
SELECT
    s.s_store_id,
    s.s_store_name,
    SUM(cs.cs_net_profit)                     AS catalog_profit,
    SUM(ss.ss_net_profit)                    AS store_profit,
    SUM(sr.sr_net_loss)                      AS return_loss,
    SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss) AS total_net_profit,
    CASE
        WHEN ib.ib_upper_bound < (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2)
            THEN 'Below Max Income'
        ELSE 'At Max Income'
    END                                       AS income_band_category,
    RANK() OVER (ORDER BY (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) - SUM(sr.sr_net_loss)) DESC) AS profit_rank,
    EXISTS (SELECT 1 FROM reason r2 WHERE r2.r_reason_desc LIKE '%damaged%') AS has_damaged_reason
FROM catalog_sales cs
JOIN time_dim td1 ON cs.cs_sold_time_sk = td1.t_time_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN sampled_inv inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
JOIN store_sales ss ON td1.t_time_sk = ss.ss_sold_time_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON ss.ss_item_sk = sr.sr_item_sk AND ss.ss_ticket_number = sr.sr_ticket_number
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr ON r.r_reason_sk = wr.wr_reason_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN time_dim td2 ON wr.wr_returned_time_sk = td2.t_time_sk
WHERE cs.cs_quantity > 5
  AND ss.ss_quantity > 3
  AND ib.ib_upper_bound > 60000
GROUP BY s.s_store_id, s.s_store_name, ib.ib_upper_bound
ORDER BY total_net_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
