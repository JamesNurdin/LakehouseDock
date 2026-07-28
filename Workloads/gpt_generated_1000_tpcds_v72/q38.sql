WITH high_value_returns AS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 100
    LIMIT 1
)
SELECT
    sm_cs.sm_type                     AS ship_mode_type,
    p.p_promo_name                    AS promotion_name,
    i_cs.i_category                   AS item_category,
    SUM(cs.cs_net_profit)             AS total_net_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(cs.cs_quantity)               AS avg_quantity_sold,
    SUM(sr.sr_return_amt)             AS total_store_return_amount,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_store_returns
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number               -- join rule 10
JOIN item i_cr
    ON cr.cr_item_sk = i_cr.i_item_sk                         -- join rule 6
JOIN ship_mode sm_cr
    ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk            -- join rule 8
JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk                    -- join rule 9
JOIN item i_cs
    ON cs.cs_item_sk = i_cs.i_item_sk                         -- join rule 4
JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk            -- join rule 3
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk                         -- join rule 5
JOIN item i_promo
    ON p.p_item_sk = i_promo.i_item_sk                        -- join rule 11
JOIN store_returns sr
    ON sr.sr_item_sk = i_cr.i_item_sk                         -- store_returns to the same item used by catalog_returns (valid via rule 1)
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk                    -- join rule 2
WHERE EXISTS (SELECT 1 FROM high_value_returns)
  AND sm_cs.sm_code = 'AIR'                                   -- example filter using realistic code
  AND i_cs.i_category = 'Electronics'
GROUP BY sm_cs.sm_type, p.p_promo_name, i_cs.i_category
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
