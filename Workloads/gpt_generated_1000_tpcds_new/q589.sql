WITH
    sampled_wh AS (
        SELECT
            w_warehouse_sk,
            w_warehouse_name,
            w_warehouse_id,
            w_zip,
            regexp_extract(w_warehouse_id, '(\\d+)$') AS wh_id_suffix
        FROM warehouse
        TABLESAMPLE BERNOULLI (10)
    ),

    returns AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_warehouse_sk,
            cr.cr_return_amount,
            d.d_current_quarter,
            d.d_day_name,
            regexp_like(d.d_day_name, '^S.*') AS is_weekend_day
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_current_quarter = 'Y'
    ),

    inventory_days AS (
        SELECT
            inv.inv_date_sk,
            inv.inv_warehouse_sk,
            inv.inv_quantity_on_hand,
            d.d_current_quarter,
            d.d_day_name
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        WHERE d.d_current_quarter = 'Y'
    ),

    full_joined AS (
        SELECT
            COALESCE(r.cr_returned_date_sk, i.inv_date_sk) AS date_sk,
            r.cr_warehouse_sk,
            i.inv_warehouse_sk,
            r.cr_return_amount,
            i.inv_quantity_on_hand,
            r.d_day_name AS return_day,
            i.d_day_name AS inventory_day,
            CASE
                WHEN r.cr_returned_date_sk IS NULL THEN 'InventoryOnly'
                WHEN i.inv_date_sk IS NULL THEN 'ReturnOnly'
                ELSE 'Both'
            END AS source_flag
        FROM returns r
        FULL OUTER JOIN inventory_days i
            ON r.cr_returned_date_sk = i.inv_date_sk
    ),

    diff_keys AS (
        SELECT cr_warehouse_sk
        FROM catalog_returns
        WHERE cr_return_amount > 150
        EXCEPT
        SELECT inv_warehouse_sk
        FROM inventory
        WHERE inv_quantity_on_hand < 20
    ),

    intersect_keys AS (
        SELECT cr_warehouse_sk
        FROM catalog_returns
        WHERE cr_return_quantity >= 30
        INTERSECT
        SELECT inv_warehouse_sk
        FROM inventory
        WHERE inv_quantity_on_hand >= 100
    ),

    final AS (
        SELECT
            fj.date_sk,
            fj.source_flag,
            COALESCE(fj.cr_warehouse_sk, fj.inv_warehouse_sk) AS warehouse_sk,
            sj.w_warehouse_name,
            CONCAT(sj.w_warehouse_name, ' - ', d.d_quarter_name) AS warehouse_quarter,
            SUBSTRING(sj.w_zip, 1, 5) AS zip_prefix,
            fj.cr_return_amount,
            fj.inv_quantity_on_hand,
            ROW_NUMBER() OVER (ORDER BY fj.date_sk DESC) AS rn
        FROM full_joined fj
        LEFT JOIN sampled_wh sj
            ON sj.w_warehouse_sk = COALESCE(fj.cr_warehouse_sk, fj.inv_warehouse_sk)
        LEFT JOIN date_dim d
            ON d.d_date_sk = fj.date_sk
        WHERE fj.source_flag <> 'InventoryOnly'
          AND regexp_like(sj.w_warehouse_name, 'Center|Facility')
          AND sj.wh_id_suffix LIKE '0%'
    )
SELECT *
FROM final
WHERE warehouse_sk IN (SELECT cr_warehouse_sk FROM diff_keys)
   OR warehouse_sk IN (SELECT cr_warehouse_sk FROM intersect_keys)
ORDER BY rn
LIMIT 100
