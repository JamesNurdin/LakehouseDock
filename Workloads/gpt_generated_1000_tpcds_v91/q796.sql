WITH inv_wh AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        inv.inv_date_sk,
        inv.inv_warehouse_sk,
        w.w_warehouse_id,
        w.w_state,
        w.w_warehouse_name
    FROM inventory inv
    FULL OUTER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
base AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_category_id,
        i.i_class,
        i.i_brand,
        i.i_size,
        iw.inv_quantity_on_hand,
        iw.inv_date_sk,
        iw.w_warehouse_id,
        iw.w_state,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        p.p_promo_id,
        p.p_discount_active,
        p.p_channel_tv,
        p.p_cost
    FROM item i
    LEFT JOIN inv_wh iw ON iw.inv_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE i.i_category_id IN (4,5,6,9)
      AND iw.inv_quantity_on_hand > 200
      AND iw.w_state = 'CA'
      AND p.p_discount_active = 'N'
      AND i.i_size IN ('large', 'extra large')
),
item_stats AS (
    SELECT
        i_item_sk,
        i_item_id,
        i_product_name,
        i_category,
        i_category_id,
        i_class,
        i_brand,
        i_size,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand,
        COUNT(DISTINCT w_warehouse_id) AS distinct_warehouses,
        SUM(sr_return_quantity) AS total_store_return_qty,
        SUM(sr_return_amt) AS total_store_return_amt,
        SUM(sr_net_loss) AS total_store_net_loss,
        SUM(wr_return_quantity) AS total_web_return_qty,
        SUM(wr_return_amt) AS total_web_return_amt,
        SUM(wr_net_loss) AS total_web_net_loss,
        COUNT(DISTINCT p_promo_id) AS promo_count,
        SUM(CASE WHEN p_channel_tv = 'N' THEN p_cost ELSE 0 END) AS total_promo_cost_tv_n,
        CASE
            WHEN i_size = 'large' THEN 'Large'
            WHEN i_size = 'extra large' THEN 'XL'
            ELSE 'Other'
        END AS size_category
    FROM base
    GROUP BY
        i_item_sk,
        i_item_id,
        i_product_name,
        i_category,
        i_category_id,
        i_class,
        i_brand,
        i_size
),
aggregated AS (
    SELECT
        i_category,
        i_brand,
        SUM(total_qty_on_hand) AS sum_qty_on_hand,
        AVG(total_store_net_loss) AS avg_store_net_loss,
        AVG(total_web_net_loss) AS avg_web_net_loss,
        AVG(total_store_net_loss + total_web_net_loss) AS avg_total_net_loss,
        COUNT(*) AS num_items
    FROM item_stats
    WHERE total_promo_cost_tv_n > (
        SELECT AVG(total_promo_cost_tv_n)
        FROM item_stats
        WHERE total_promo_cost_tv_n IS NOT NULL
    )
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = item_stats.i_item_sk
            AND sr2.sr_net_loss > 0
      )
    GROUP BY i_category, i_brand
    HAVING COUNT(*) >= 3
)
SELECT
    i_category,
    i_brand,
    sum_qty_on_hand,
    avg_store_net_loss,
    avg_web_net_loss,
    num_items,
    CASE
        WHEN avg_total_net_loss > 1000 THEN 'High Loss'
        WHEN avg_total_net_loss BETWEEN 100 AND 1000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category,
    sum_qty_on_hand / NULLIF(num_items, 0) AS avg_qty_per_brand,
    (SELECT AVG(total_promo_cost_tv_n)
     FROM item_stats
     WHERE total_promo_cost_tv_n IS NOT NULL) AS overall_avg_promo_cost,
    SUM(sum_qty_on_hand) OVER (PARTITION BY i_category ORDER BY i_brand ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_qty_by_category_brand
FROM aggregated
ORDER BY sum_qty_on_hand DESC
LIMIT 100
