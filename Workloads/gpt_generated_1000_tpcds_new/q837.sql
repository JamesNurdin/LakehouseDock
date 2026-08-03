WITH sampled_inventory AS (
    SELECT
        inv_item_sk,
        inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),

online_only_returns AS (
    SELECT wr_item_sk
    FROM web_returns
    EXCEPT
    SELECT sr_item_sk
    FROM store_returns
),

web_sales_agg AS (
    SELECT
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_cnt,
        REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1) AS first_word,
        CONCAT(i.i_brand, ' - ', i.i_item_desc) AS brand_desc_concat,
        l.short_desc
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    CROSS JOIN LATERAL (
        SELECT CONCAT(i.i_brand, ':', SUBSTR(i.i_item_desc, 1, 10)) AS short_desc
    ) AS l
    WHERE REGEXP_LIKE(i.i_item_desc, '[A-Z]{3,}')
      AND i.i_item_id LIKE 'ITEM_%'
    GROUP BY
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        REGEXP_EXTRACT(i.i_item_desc, '(\\w+)', 1),
        CONCAT(i.i_brand, ' - ', i.i_item_desc),
        l.short_desc
),

filtered_items AS (
    SELECT
        wa.*,
        inv.inv_quantity_on_hand
    FROM web_sales_agg wa
    JOIN sampled_inventory inv
        ON wa.i_item_sk = inv.inv_item_sk
    JOIN online_only_returns oor
        ON wa.i_item_sk = oor.wr_item_sk
),

ranked AS (
    SELECT
        f.ib_lower_bound,
        f.ib_upper_bound,
        f.i_item_id,
        f.i_brand,
        f.total_sales,
        f.order_cnt,
        f.first_word,
        f.brand_desc_concat,
        f.short_desc,
        f.inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY f.ib_lower_bound ORDER BY f.total_sales DESC) AS rn
    FROM filtered_items f
)

SELECT
    ib_lower_bound,
    ib_upper_bound,
    i_item_id,
    i_brand,
    total_sales,
    order_cnt,
    first_word,
    brand_desc_concat,
    short_desc,
    inv_quantity_on_hand
FROM ranked
WHERE rn <= 5
ORDER BY ib_lower_bound, rn
LIMIT 100
