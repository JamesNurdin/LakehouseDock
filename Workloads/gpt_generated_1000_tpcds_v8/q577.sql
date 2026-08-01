WITH
    max_ret AS (
        SELECT MAX(cr_return_amount) AS max_amount
        FROM catalog_returns
    ),
    sub_a AS (
        SELECT
            cc.cc_call_center_id,
            w.w_warehouse_id,
            SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cr.cr_return_amount > 0
          AND NOT EXISTS (
                SELECT 1
                FROM store_returns sr
                JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
                WHERE ca.ca_state = cc.cc_state
          )
        GROUP BY cc.cc_call_center_id, w.w_warehouse_id
    ),
    sub_b AS (
        SELECT DISTINCT
            cc.cc_call_center_id,
            w.w_warehouse_id,
            0.0 AS total_return_amount
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cr.cr_return_amount > (SELECT max_amount / 2 FROM max_ret)
    ),
    sub_c AS (
        SELECT
            cc.cc_call_center_id,
            w.w_warehouse_id,
            SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cr.cr_return_amount >= 100
        GROUP BY ROLLUP (cc.cc_call_center_id, w.w_warehouse_id)
    ),
    sub_d AS (
        SELECT
            cc.cc_call_center_id,
            w.w_warehouse_id,
            SUM(cr.cr_return_amount) AS total_return_amount
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cr.cr_return_amount < 20
        GROUP BY ROLLUP (cc.cc_call_center_id, w.w_warehouse_id)
    )
SELECT *
FROM (
        SELECT * FROM sub_a
        UNION ALL
        SELECT * FROM sub_b
     ) AS u
INTERSECT
SELECT * FROM sub_c
EXCEPT
SELECT * FROM sub_d
ORDER BY cc_call_center_id NULLS LAST, w_warehouse_id NULLS LAST
OFFSET 20 LIMIT 100
