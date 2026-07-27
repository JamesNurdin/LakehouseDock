WITH inv_agg AS (
    SELECT
        i.inv_item_sk,
        i.inv_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        MAX(i.inv_quantity_on_hand) AS max_qty
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 1915               -- filter predicate 1
      AND i.inv_quantity_on_hand > 200  -- filter predicate 2
    GROUP BY i.inv_item_sk, i.inv_warehouse_sk, d.d_year, d.d_month_seq
)
SELECT DISTINCT
    p.p_promo_id,
    p.p_promo_name,
    ds.d_date AS promo_start_date,
    de.d_date AS promo_end_date,
    ia.inv_item_sk,
    ia.total_qty,
    CASE 
        WHEN ia.total_qty >= 500 THEN 'High'
        WHEN ia.total_qty >= 300 THEN 'Medium'
        ELSE 'Low'
    END AS qty_category,
    RANK() OVER (PARTITION BY ia.inv_item_sk ORDER BY ds.d_date) AS promo_start_rank,
    (SELECT COUNT(*) FROM inventory i2 WHERE i2.inv_item_sk = ia.inv_item_sk) AS total_inventory_records
FROM promotion p
JOIN date_dim ds
    ON p.p_start_date_sk = ds.d_date_sk
JOIN date_dim de
    ON p.p_end_date_sk = de.d_date_sk
JOIN inv_agg ia
    ON p.p_item_sk = ia.inv_item_sk
WHERE p.p_channel_radio = 'N'                 -- filter predicate 3
  AND ds.d_month_seq BETWEEN 1 AND 12        -- filter predicate 4
  AND de.d_year = 1915                       -- filter predicate 5
ORDER BY ia.total_qty DESC, p.p_promo_id
LIMIT 100
