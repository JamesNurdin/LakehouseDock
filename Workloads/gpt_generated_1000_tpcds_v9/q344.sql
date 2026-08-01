WITH RECURSIVE date_range (date_sk) AS (
    SELECT 20210101
    UNION ALL
    SELECT date_sk + 1 FROM date_range WHERE date_sk < 20210105
)
SELECT
    i.i_category,
    s.s_state,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    SUM(cs.cs_net_paid) AS total_catalog_sales,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
    AVG(wr.wr_return_amt) AS avg_web_return_amount,
    CASE
        WHEN SUM(cr.cr_net_loss) > 0 THEN 'Loss'
        ELSE 'Profit'
    END AS loss_status,
    (SELECT SUM(inv2.inv_quantity_on_hand)
     FROM inventory inv2
     WHERE inv2.inv_item_sk = i.i_item_sk) AS total_inventory_on_hand
FROM
    (SELECT * FROM item TABLESAMPLE BERNOULLI (5)) i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer cust ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_range dr ON cs.cs_sold_date_sk = dr.date_sk
WHERE
    sm.sm_type = 'OVERNIGHT'
    AND hd.hd_buy_potential = '>10000'
    AND inv.inv_quantity_on_hand > 100
    AND cr.cr_reversed_charge > 50.0
GROUP BY
    i.i_category,
    s.s_state,
    sm.sm_type,
    i.i_item_sk
ORDER BY
    total_catalog_sales DESC
LIMIT 100
