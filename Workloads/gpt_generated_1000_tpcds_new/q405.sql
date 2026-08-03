WITH
    -- Item dimension used for sales and returns
    item_f AS (
        SELECT
            i_item_sk,
            i_category,
            i_product_name,
            i_current_price
        FROM item
    ),
    -- Sales fact filtered by a scalar subquery (average profit)
    sales_f AS (
        SELECT
            ss_sold_date_sk,
            ss_item_sk,
            ss_store_sk,
            ss_promo_sk,
            ss_addr_sk,
            ss_cdemo_sk,
            ss_hdemo_sk,
            ss_quantity,
            ss_net_paid,
            ss_net_profit
        FROM store_sales
        WHERE ss_net_profit > (
            SELECT AVG(ss_net_profit) FROM store_sales
        )
    )
SELECT
    s.s_store_name,
    i_f.i_category,
    p.p_promo_name,
    SUM(ssf.ss_quantity)                               AS total_quantity,
    SUM(ssf.ss_net_paid)                               AS total_net_paid,
    SUM(ssf.ss_net_profit)                             AS total_net_profit,
    CASE
        WHEN SUM(ssf.ss_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END                                               AS profit_status,
    COALESCE(cr.cr_return_amount, 0)                  AS catalog_return_amount,
    COALESCE(wr.wr_return_amt, 0)                     AS web_return_amount,
    SUM(inv.inv_quantity_on_hand)                     AS total_inventory_on_hand,
    t.status                                          AS customer_status
FROM sales_f ssf
JOIN item_f i_f
    ON ssf.ss_item_sk = i_f.i_item_sk
JOIN store s
    ON ssf.ss_store_sk = s.s_store_sk
JOIN promotion p
    ON ssf.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = i_f.i_item_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = i_f.i_item_sk
LEFT JOIN customer_address ca
    ON ssf.ss_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd
    ON ssf.ss_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON ssf.ss_hdemo_sk = hd.hd_demo_sk
LEFT JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN reason r2
    ON wr.wr_reason_sk = r2.r_reason_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i_f.i_item_sk
LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
-- Unnest a literal array to add a status dimension
CROSS JOIN UNNEST(ARRAY['New', 'Returning', 'VIP']) AS t(status)
WHERE i_f.i_current_price > (
    SELECT MAX(i_current_price)
    FROM item
    WHERE i_category = i_f.i_category
)
GROUP BY
    s.s_store_name,
    i_f.i_category,
    p.p_promo_name,
    cr.cr_return_amount,
    wr.wr_return_amt,
    t.status
ORDER BY total_net_paid DESC
LIMIT 100
