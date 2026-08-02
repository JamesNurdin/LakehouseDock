WITH store_ret AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        c.c_customer_id AS customer_id,
        i.i_item_id AS item_id,
        sr.sr_return_amt AS return_amount,
        d.d_date AS return_date,
        inv_q.qty AS inventory_quantity,
        (
            SELECT SUM(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = i.i_item_sk
        ) AS total_catalog_sales_price,
        CAST(NULL AS varchar) AS word
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT inv.inv_quantity_on_hand AS qty
        FROM inventory inv
        WHERE inv.inv_item_sk = sr.sr_item_sk
          AND inv.inv_date_sk = d.d_date_sk
        ORDER BY inv.inv_date_sk DESC
        LIMIT 1
    ) inv_q
    WHERE d.d_year = 2001
      AND d.d_holiday = 'N'
      AND NOT EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = sr.sr_item_sk
            AND inv2.inv_date_sk = d.d_date_sk
            AND inv2.inv_quantity_on_hand > 0
      )
),
catalog_ret AS (
    SELECT
        CAST(NULL AS integer) AS store_sk,
        c.c_customer_id AS customer_id,
        i.i_item_id AS item_id,
        cr.cr_return_amount AS return_amount,
        d.d_date AS return_date,
        inv_q.qty AS inventory_quantity,
        (
            SELECT SUM(cs.cs_ext_sales_price)
            FROM catalog_sales cs
            WHERE cs.cs_item_sk = i.i_item_sk
        ) AS total_catalog_sales_price,
        w.word
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    CROSS JOIN LATERAL (
        SELECT inv.inv_quantity_on_hand AS qty
        FROM inventory inv
        WHERE inv.inv_item_sk = cr.cr_item_sk
          AND inv.inv_date_sk = d.d_date_sk
        ORDER BY inv.inv_date_sk DESC
        LIMIT 1
    ) inv_q
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS w(word)
    WHERE d.d_year = 2001
      AND d.d_holiday = 'N'
      AND NOT EXISTS (
          SELECT 1
          FROM inventory inv2
          WHERE inv2.inv_item_sk = cr.cr_item_sk
            AND inv2.inv_date_sk = d.d_date_sk
            AND inv2.inv_quantity_on_hand > 0
      )
),
all_returns AS (
    SELECT
        store_sk,
        customer_id,
        item_id,
        return_amount,
        return_date,
        inventory_quantity,
        total_catalog_sales_price,
        word
    FROM store_ret
    UNION ALL
    SELECT
        store_sk,
        customer_id,
        item_id,
        return_amount,
        return_date,
        inventory_quantity,
        total_catalog_sales_price,
        word
    FROM catalog_ret
)
SELECT DISTINCT
    COALESCE(ar.store_sk, sd.s_store_sk) AS store_sk,
    sd.s_store_name,
    sd.s_state,
    ar.customer_id,
    ar.item_id,
    ar.return_amount,
    ar.return_date,
    ar.inventory_quantity,
    ar.total_catalog_sales_price,
    ar.word,
    (
        SELECT SUM(inner_ar.return_amount)
        FROM all_returns inner_ar
        WHERE inner_ar.item_id = ar.item_id
    ) AS sum_return_amount_for_item
FROM all_returns ar
FULL OUTER JOIN store sd ON ar.store_sk = sd.s_store_sk
WHERE ar.return_amount > 0
ORDER BY ar.return_date DESC
LIMIT 100
