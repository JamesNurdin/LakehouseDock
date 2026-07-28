WITH catalog_part AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        'catalog' AS channel,
        cp.cp_type,
        avg(cr.cr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
        count(*) AS return_cnt
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT cp_type
        FROM catalog_page
        WHERE cp_catalog_page_sk = cr.cr_catalog_page_sk
    ) cp
    WHERE cr.cr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND i.i_current_price > 100
    GROUP BY i.i_item_id, i.i_item_desc, cp.cp_type
),
store_part AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        'store' AS channel,
        CAST(NULL AS varchar) AS cp_type,
        avg(sr.sr_return_amt_inc_tax) AS avg_return_amount_inc_tax,
        count(*) AS return_cnt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2452000
      AND i.i_current_price > 100
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT *
FROM catalog_part
UNION ALL
SELECT *
FROM store_part
ORDER BY i_item_id DESC, channel
LIMIT 100
