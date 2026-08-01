WITH promo_items AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        regexp_extract(p.p_channel_details, '([A-Za-z]+)', 1) AS keyword
    FROM promotion p
    WHERE regexp_like(p.p_channel_details, '(prize|achievement|local)')
),

catalog_agg AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_catalog_qty,
        SUM(cs.cs_net_paid) AS total_catalog_paid
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cs.cs_item_sk
),

web_agg AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_qty,
        SUM(ws.ws_net_paid) AS total_web_paid
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_item_sk
),

item_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        CONCAT(i.i_brand, ' - ', i.i_color) AS brand_color,
        COALESCE(ca.total_catalog_qty, 0) AS total_catalog_qty,
        COALESCE(ca.total_catalog_paid, 0) AS total_catalog_paid,
        COALESCE(wa.total_web_qty, 0) AS total_web_qty,
        COALESCE(wa.total_web_paid, 0) AS total_web_paid
    FROM item i
    LEFT JOIN catalog_agg ca ON ca.cs_item_sk = i.i_item_sk
    LEFT JOIN web_agg wa ON wa.ws_item_sk = i.i_item_sk
),

intersect_items AS (
    SELECT DISTINCT cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002

    INTERSECT

    SELECT DISTINCT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
)

SELECT DISTINCT
    iSA.i_item_id,
    iSA.i_product_name,
    iSA.brand_color,
    (iSA.total_catalog_qty + iSA.total_web_qty) AS total_quantity_sold,
    (iSA.total_catalog_paid + iSA.total_web_paid) AS total_sales_amount,
    pi.keyword,
    CASE
        WHEN (iSA.total_catalog_paid + iSA.total_web_paid) > (
            SELECT AVG(cs.cs_net_paid)
            FROM catalog_sales cs
            JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
            WHERE d.d_year = 2002
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS sales_category
FROM intersect_items ii
JOIN item_sales_agg iSA ON iSA.i_item_sk = ii.item_sk
JOIN promo_items pi ON pi.p_item_sk = iSA.i_item_sk
WHERE iSA.i_product_name LIKE 'A%'
  AND regexp_like(iSA.i_product_name, '^A[\\w\\s]{3,20}$')
  AND EXISTS (
        SELECT 1
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        WHERE inv.inv_item_sk = iSA.i_item_sk
          AND d.d_year = 2002
          AND inv.inv_quantity_on_hand > 500
  )
ORDER BY total_quantity_sold DESC, iSA.i_item_id
LIMIT 100
