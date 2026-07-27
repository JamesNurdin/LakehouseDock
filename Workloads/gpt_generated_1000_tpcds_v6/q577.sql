WITH sales_agg AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    cc.cc_division_name,
    cp.cp_catalog_page_number,
    i.i_item_id,
    sm.sm_type,
    r_store.r_reason_desc        AS store_return_reason,
    r_cat.r_reason_desc          AS catalog_return_reason,
    sr.sr_return_amt_inc_tax,
    sr.sr_net_loss,
    cr.cr_return_amount,
    cs_agg.cs_net_profit,
    RANK() OVER (PARTITION BY cc.cc_division_name ORDER BY sr.sr_net_loss DESC) AS loss_rank,
    CASE
        WHEN sr.sr_net_loss > (
            SELECT AVG(sr2.sr_net_loss)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = sr.sr_reason_sk
        ) THEN 'High'
        ELSE 'Low'
    END AS loss_category
FROM sales_agg cs_agg
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN customer_address ca
    ON cs_agg.cs_bill_addr_sk = ca.ca_address_sk
JOIN store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
JOIN reason r_store
    ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs_agg.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
JOIN reason r_cat
    ON cr.cr_reason_sk = r_cat.r_reason_sk
WHERE
    cc.cc_division_name = 'anti'
    AND cp.cp_catalog_page_number BETWEEN 10 AND 20
    AND i.i_current_price > 100
    AND sm.sm_type = 'AIR'
    AND sr.sr_net_loss > 500
ORDER BY loss_rank
LIMIT 100
