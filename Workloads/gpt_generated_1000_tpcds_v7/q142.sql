WITH
    -- Alias for promotion linked to items (outer join, keep items even without a promotion)
    p_item AS (
        SELECT p.p_promo_sk
        FROM promotion p
        WHERE p.p_channel_catalog = 'N'
    )
SELECT
    i_sales.i_category,
    i_sales.i_brand,
    SUM(cs.cs_net_profit)               AS catalog_net_profit,
    SUM(ss.ss_net_profit)               AS store_net_profit,
    SUM(cr.cr_net_loss)                 AS total_return_loss,
    COUNT(DISTINCT cr.cr_order_number)  AS returns_cnt
FROM catalog_returns cr
JOIN catalog_sales cs
    ON cr.cr_order_number = cs.cs_order_number
JOIN item i_cr
    ON cr.cr_item_sk = i_cr.i_item_sk
LEFT JOIN promotion p_item_join
    ON i_cr.i_item_sk = p_item_join.p_item_sk
    AND p_item_join.p_channel_catalog = 'N'
JOIN time_dim t_ret
    ON cr.cr_returned_time_sk = t_ret.t_time_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN household_demographics hd_returning
    ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN time_dim t_sales
    ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN item i_sales
    ON cs.cs_item_sk = i_sales.i_item_sk
JOIN promotion p_sales
    ON cs.cs_promo_sk = p_sales.p_promo_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_ship
    ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
    ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
-- Connect store_sales through the shared item dimension
JOIN store_sales ss
    ON ss.ss_item_sk = i_sales.i_item_sk
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN promotion p_store
    ON ss.ss_promo_sk = p_store.p_promo_sk
JOIN time_dim t_store
    ON ss.ss_sold_time_sk = t_store.t_time_sk
WHERE t_sales.t_hour BETWEEN 9 AND 17
GROUP BY i_sales.i_category, i_sales.i_brand
ORDER BY catalog_net_profit DESC
LIMIT 100
