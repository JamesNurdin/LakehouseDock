WITH inv_agg AS (
    SELECT i.i_item_sk,
           SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk
)
SELECT
    i1.i_category,
    sm.sm_code,
    CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_bucket,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(cr.cr_net_loss) AS total_return_loss,
    SUM(sr.sr_return_amt) AS total_store_return,
    inv_agg.total_on_hand,
    COUNT(DISTINCT c_bill.c_customer_sk) AS distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY i1.i_category ORDER BY SUM(cs.cs_net_profit) DESC) AS rank_by_profit
FROM catalog_sales cs
JOIN time_dim t_sales ON cs.cs_sold_time_sk = t_sales.t_time_sk
JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i1 ON cs.cs_item_sk = i1.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
-- catalog returns
JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
JOIN item i2 ON cr.cr_item_sk = i2.i_item_sk
JOIN time_dim t_return ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
-- store returns (re‑using item and time_dim under different aliases)
JOIN store_returns sr ON sr.sr_item_sk = i1.i_item_sk
JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN store s ON sr.sr_store_sk = s.s_store_sk
JOIN customer c_store ON sr.sr_customer_sk = c_store.c_customer_sk
JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
JOIN customer_demographics cd_store ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
JOIN household_demographics hd_store ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
-- web page activity
JOIN web_page wp ON wp.wp_customer_sk = c_bill.c_customer_sk
-- inventory aggregation
JOIN inv_agg ON inv_agg.i_item_sk = i1.i_item_sk
WHERE i1.i_category_id IN (1, 2, 3)
GROUP BY
    i1.i_category,
    sm.sm_code,
    CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END,
    inv_agg.total_on_hand
ORDER BY total_profit DESC
LIMIT 100
