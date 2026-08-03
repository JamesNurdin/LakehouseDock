WITH item_words AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           w AS word
    FROM item i
    CROSS JOIN UNNEST(split(i.i_item_desc, ' ')) AS t(w)
),
return_agg AS (
    SELECT cr.cr_item_sk,
           SUM(cr.cr_return_amount) AS total_return_amount,
           COUNT(*) AS return_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
web_sales_agg AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_cnt
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
full_join AS (
    SELECT
        cc.cc_call_center_id,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_item_sk,
        cr.cr_returning_customer_sk,
        CASE WHEN cr.cr_return_amount > 1000 THEN 'HIGH' ELSE 'LOW' END AS return_level
    FROM call_center cc
    FULL OUTER JOIN catalog_returns cr
        ON cc.cc_call_center_sk = cr.cr_call_center_sk
),
union_query AS (
    SELECT ws.ws_order_number AS order_id,
           ws.ws_ext_sales_price AS amount,
           'WEB' AS source
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 500
    UNION
    SELECT cr.cr_order_number AS order_id,
           cr.cr_return_amount AS amount,
           'CATALOG' AS source
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 500
)
SELECT
    fw.cc_call_center_id,
    fw.cr_order_number,
    fw.return_level,
    COALESCE(CAST(fw.cr_return_amount AS varchar), 'No Return') AS return_amount_str,
    i.i_item_id,
    iw.word,
    ra.total_return_amount,
    wsagg.total_sales,
    uq.source,
    uq.amount
FROM full_join fw
LEFT JOIN item i
    ON i.i_item_sk = fw.cr_item_sk
LEFT JOIN item_words iw
    ON iw.i_item_sk = i.i_item_sk
LEFT JOIN return_agg ra
    ON ra.cr_item_sk = i.i_item_sk
LEFT JOIN web_sales_agg wsagg
    ON wsagg.ws_item_sk = i.i_item_sk
LEFT JOIN union_query uq
    ON uq.order_id = fw.cr_order_number
WHERE
    regexp_like(CAST(i.i_brand_id AS varchar), '500')
    AND i.i_container LIKE '%box%'
    AND EXISTS (
        SELECT 1
        FROM customer c
        JOIN household_demographics hd
            ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE c.c_customer_sk = fw.cr_returning_customer_sk
          AND ib.ib_upper_bound > 80000
    )
ORDER BY fw.return_level DESC, ra.total_return_amount DESC
LIMIT 100
