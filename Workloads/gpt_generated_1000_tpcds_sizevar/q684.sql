WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cr.cr_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cs.cs_ship_mode_sk,
        cr.cr_ship_mode_sk
    FROM catalog_sales cs
    FULL OUTER JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
),

agg_union AS (
    SELECT
        i.i_item_id                                   AS item_id,
        concat(i.i_brand, '-', i.i_color)             AS product_code,
        sm.sm_carrier                                 AS carrier,
        SUM(COALESCE(j.cs_net_paid, 0))               AS total_sales,
        SUM(COALESCE(j.cr_return_amount, 0))          AS total_returns,
        (SELECT SUM(cr_sub.cr_return_amount)
         FROM catalog_returns cr_sub
         WHERE cr_sub.cr_item_sk = i.i_item_sk)      AS overall_return_amount
    FROM joined j
    LEFT JOIN item i
        ON i.i_item_sk = COALESCE(j.cs_item_sk, j.cr_item_sk)
    LEFT JOIN ship_mode sm
        ON sm.sm_ship_mode_sk = COALESCE(j.cs_ship_mode_sk, j.cr_ship_mode_sk)
    WHERE regexp_like(i.i_product_name, '.*[A-Za-z]{5}.*')
      AND sm.sm_carrier LIKE '%UPS%'
    GROUP BY i.i_item_id, i.i_brand, i.i_color, sm.sm_carrier, i.i_item_sk

    UNION DISTINCT

    SELECT
        i2.i_item_id                                   AS item_id,
        concat(i2.i_brand, '-', i2.i_color)            AS product_code,
        sm2.sm_carrier                                 AS carrier,
        SUM(cs2.cs_net_paid)                           AS total_sales,
        CAST(0 AS decimal(7,2))                        AS total_returns,
        (SELECT SUM(cr_sub2.cr_return_amount)
         FROM catalog_returns cr_sub2
         WHERE cr_sub2.cr_item_sk = i2.i_item_sk)     AS overall_return_amount
    FROM catalog_sales cs2
    JOIN item i2
        ON cs2.cs_item_sk = i2.i_item_sk
    JOIN ship_mode sm2
        ON cs2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
    WHERE i2.i_product_name LIKE '%widget%'
    GROUP BY i2.i_item_id, i2.i_brand, i2.i_color, sm2.sm_carrier, i2.i_item_sk
),

final_set AS (
    SELECT *
    FROM agg_union
    INTERSECT
    SELECT
        i3.i_item_id                                   AS item_id,
        concat(i3.i_brand, '-', i3.i_color)            AS product_code,
        sm3.sm_carrier                                 AS carrier,
        CAST(0 AS decimal(7,2))                        AS total_sales,
        SUM(cr3.cr_return_amount)                     AS total_returns,
        (SELECT SUM(cr_sub3.cr_return_amount)
         FROM catalog_returns cr_sub3
         WHERE cr_sub3.cr_item_sk = i3.i_item_sk)     AS overall_return_amount
    FROM catalog_returns cr3
    JOIN item i3
        ON cr3.cr_item_sk = i3.i_item_sk
    JOIN ship_mode sm3
        ON cr3.cr_ship_mode_sk = sm3.sm_ship_mode_sk
    WHERE cr3.cr_return_amount > 1000
    GROUP BY i3.i_item_id, i3.i_brand, i3.i_color, sm3.sm_carrier, i3.i_item_sk
)

SELECT
    item_id,
    product_code,
    carrier,
    total_sales,
    total_returns,
    overall_return_amount
FROM final_set
ORDER BY total_returns DESC
LIMIT 100
