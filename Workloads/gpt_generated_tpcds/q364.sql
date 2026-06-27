WITH web_page_counts AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT wp.wp_web_page_sk) AS web_page_cnt
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    wh.w_warehouse_name,
    d.d_year,
    d.d_month_seq,
    SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(itm.i_current_price) AS avg_item_price,
    COUNT(DISTINCT promo.p_promo_sk) AS promo_cnt,
    COALESCE(wpc.web_page_cnt, 0) AS web_page_cnt
FROM inventory inv
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
JOIN item itm ON inv.inv_item_sk = itm.i_item_sk
JOIN warehouse wh ON inv.inv_warehouse_sk = wh.w_warehouse_sk
JOIN promotion promo
    ON promo.p_item_sk = itm.i_item_sk
    AND inv.inv_date_sk BETWEEN promo.p_start_date_sk AND promo.p_end_date_sk
LEFT JOIN web_page_counts wpc
    ON d.d_year = wpc.d_year
    AND d.d_month_seq = wpc.d_month_seq
WHERE d.d_year = 2001
GROUP BY wh.w_warehouse_name, d.d_year, d.d_month_seq, wpc.web_page_cnt
ORDER BY wh.w_warehouse_name, d.d_year, d.d_month_seq
