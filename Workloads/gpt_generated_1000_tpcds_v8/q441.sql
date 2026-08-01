WITH base_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cp.cp_catalog_page_sk,
        cp.cp_catalog_number,
        cp.cp_catalog_page_number,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt,
        -- correlated scalar subquery per call center
        (SELECT SUM(cr2.cr_return_quantity)
         FROM catalog_returns cr2
         WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk) AS total_qty_per_cc
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE
        cr.cr_return_amount > 100.00                -- predicate 1
        AND cr.cr_return_ship_cost BETWEEN 50 AND 1500   -- predicate 2
        AND cd.cd_marital_status = 'M'                 -- predicate 3
        AND cd.cd_dep_count >= 1                       -- predicate 4
        AND d_ret.d_year = 2001                        -- predicate 5
        AND cp.cp_catalog_number IN (1,2,8,15)         -- predicate 6
    GROUP BY GROUPING SETS (
        (cc.cc_call_center_sk, cc.cc_name, cp.cp_catalog_page_sk, cp.cp_catalog_number, cp.cp_catalog_page_number),
        (cc.cc_call_center_sk, cc.cc_name),
        ()
    )
)
SELECT
    b.cc_call_center_sk,
    cc2.cc_name,
    b.total_return_amount,
    b.total_return_qty,
    b.return_cnt,
    b.total_qty_per_cc,
    o.d_year AS open_year,
    (
        SELECT COUNT(DISTINCT cr3.cr_returning_customer_sk)
        FROM catalog_returns cr3
        WHERE cr3.cr_call_center_sk = b.cc_call_center_sk
    ) AS distinct_returning_customers
FROM base_agg b
LEFT JOIN call_center cc2
    ON b.cc_call_center_sk = cc2.cc_call_center_sk
FULL OUTER JOIN date_dim o
    ON cc2.cc_open_date_sk = o.d_date_sk
WHERE
    b.total_return_amount > 500
    AND b.cc_call_center_sk IN (
        SELECT cr_call_center_sk FROM catalog_returns WHERE cr_return_amount > 200
        INTERSECT
        SELECT cr_call_center_sk FROM catalog_returns WHERE cr_return_ship_cost < 100
    )
    AND b.cc_call_center_sk NOT IN (
        SELECT cr_call_center_sk FROM catalog_returns WHERE cr_return_quantity = 0
        EXCEPT
        SELECT cr_call_center_sk FROM catalog_returns WHERE cr_return_amount < 50
    )
GROUP BY ROLLUP (b.cc_call_center_sk, cc2.cc_name, o.d_year,
                 b.total_return_amount, b.total_return_qty, b.return_cnt, b.total_qty_per_cc)
HAVING SUM(b.total_return_qty) > 1000
ORDER BY b.total_return_amount DESC
LIMIT 100
