WITH sales_agg AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(*) AS sales_transactions,
        CASE WHEN SUM(ss.ss_ext_discount_amt) > 0 THEN 'DISCOUNTED' ELSE 'FULL_PRICE' END AS price_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number
)
SELECT
    d.d_date,
    s.s_store_name,
    i.i_item_desc,
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    p.p_promo_name,
    cd.cd_gender,
    sa.total_profit,
    RANK() OVER (PARTITION BY s.s_store_sk ORDER BY sa.total_profit DESC) AS profit_rank,
    sa.price_type,
    (
        SELECT AVG(inv3.inv_quantity_on_hand)
        FROM inventory inv3
        WHERE inv3.inv_item_sk = sa.ss_item_sk
    ) AS avg_inventory_qty,
    COALESCE(wr.wr_return_quantity, 0) AS web_return_qty,
    COALESCE(sr.sr_return_quantity, 0) AS store_return_qty,
    cc.cc_name AS call_center_name,
    cp.cp_description AS catalog_page_desc,
    w.w_warehouse_name,
    wp.wp_url
FROM sales_agg sa
JOIN date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN item i ON sa.ss_item_sk = i.i_item_sk
JOIN customer c ON sa.ss_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN promotion p ON sa.ss_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr ON sr.sr_ticket_number = sa.ss_ticket_number AND sr.sr_item_sk = sa.ss_item_sk
LEFT JOIN catalog_returns cr ON cr.cr_item_sk = sa.ss_item_sk AND cr.cr_returned_date_sk = sa.ss_sold_date_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = sa.ss_item_sk AND wr.wr_returned_date_sk = sa.ss_sold_date_sk
LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN inventory inv ON inv.inv_item_sk = sa.ss_item_sk AND inv.inv_date_sk = sa.ss_sold_date_sk
LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND i.i_brand = 'Brand#23'
  AND s.s_state = 'CA'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = sa.ss_item_sk
          AND cr2.cr_returned_date_sk = sa.ss_sold_date_sk
    )
ORDER BY sa.total_profit DESC
LIMIT 100
