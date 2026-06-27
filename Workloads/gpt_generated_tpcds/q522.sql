WITH inventory_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_warehouse_name,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    JOIN date_dim di ON inv.inv_date_sk = di.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE di.d_date >= DATE '2000-01-01'
      AND di.d_date < DATE '2001-01-01'
    GROUP BY i.i_item_sk,
             i.i_product_name,
             i.i_category,
             w.w_warehouse_sk,
             w.w_warehouse_id,
             w.w_warehouse_name
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_net_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS return_count
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE dr.d_date >= DATE '2000-01-01'
      AND dr.d_date < DATE '2001-01-01'
    GROUP BY i.i_item_sk,
             i.i_product_name,
             i.i_category
),
promotion_agg AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_category,
        SUM(p.p_cost) AS total_promo_cost,
        COUNT(*) AS promo_count
    FROM promotion p
    JOIN date_dim dp_start ON p.p_start_date_sk = dp_start.d_date_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE dp_start.d_date >= DATE '2000-01-01'
      AND dp_start.d_date < DATE '2001-01-01'
    GROUP BY i.i_item_sk,
             i.i_product_name,
             i.i_category
)
SELECT
    ia.i_item_sk,
    ia.i_product_name,
    ia.i_category,
    ia.w_warehouse_id,
    ia.w_warehouse_name,
    ia.total_quantity_on_hand,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    COALESCE(ra.total_return_amount, 0) AS total_return_amount,
    COALESCE(pa.total_promo_cost, 0) AS total_promo_cost,
    i.i_current_price
FROM inventory_agg ia
LEFT JOIN returns_agg ra ON ia.i_item_sk = ra.i_item_sk
LEFT JOIN promotion_agg pa ON ia.i_item_sk = pa.i_item_sk
JOIN item i ON ia.i_item_sk = i.i_item_sk
ORDER BY ia.total_quantity_on_hand DESC
LIMIT 100
