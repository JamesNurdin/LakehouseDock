WITH inv_agg AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_item_sk
),
promo_distinct AS (
    SELECT DISTINCT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_demo,
        p.p_discount_active,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_item_sk
    FROM promotion p
    WHERE p.p_discount_active = 'Y'
)
SELECT
    d.d_date,
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    pd.p_promo_name,
    ws.web_name,
    cp.cp_catalog_number,
    ss.ss_quantity,
    ss.ss_net_paid,
    ss.ss_net_profit,
    inv_agg.total_qty_on_hand,
    CASE
        WHEN inv_agg.total_qty_on_hand > 500 THEN 'High Inventory'
        ELSE 'Low Inventory'
    END AS inventory_level,
    RANK() OVER (PARTITION BY d.d_year ORDER BY ss.ss_net_profit DESC) AS profit_rank_by_year
FROM store_sales ss
JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
JOIN promo_distinct pd
    ON ss.ss_promo_sk = pd.p_promo_sk
JOIN inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
   AND inv_agg.inv_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cp.cp_start_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2002
  AND i.i_brand_id = 5002002
  AND pd.p_channel_demo = 'Y'
ORDER BY d.d_date, profit_rank_by_year
LIMIT 100
