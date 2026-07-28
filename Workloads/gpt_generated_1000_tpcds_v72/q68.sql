WITH catalog_agg AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS order_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.promotion p
        ON p.p_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '(?i)Premium')
      AND p.p_promo_name LIKE 'Summer%'
    GROUP BY cr.cr_item_sk
    HAVING SUM(cr.cr_net_loss) > 1000
)
SELECT DISTINCT
    i.i_item_id,
    i.i_product_name,
    p.p_promo_id,
    ca.total_net_loss,
    w.w_warehouse_name,
    substring(i.i_product_name, 1, 10) AS product_name_prefix,
    regexp_extract(i.i_item_desc, '(?i)(Premium.*)', 1) AS premium_desc
FROM catalog_agg ca
JOIN tpcds.item i
    ON ca.cr_item_sk = i.i_item_sk
JOIN tpcds.promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
JOIN tpcds.warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
WHERE EXISTS (
    SELECT 1
    FROM tpcds.inventory inv
    JOIN tpcds.date_dim d
        ON inv.inv_date_sk = d.d_date_sk
    WHERE inv.inv_item_sk = i.i_item_sk
      AND d.d_year = 2001
      AND inv.inv_quantity_on_hand > 0
)
ORDER BY ca.total_net_loss DESC
LIMIT 100
