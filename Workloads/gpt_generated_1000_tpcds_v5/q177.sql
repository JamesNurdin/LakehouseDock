WITH returns_agg AS (
    SELECT
        cr_call_center_sk,
        cr_catalog_page_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_ship_cost > 0
      AND cr_warehouse_sk IN (8, 14)
      AND cr_returned_date_sk BETWEEN 2450900 AND 2451500
    GROUP BY cr_call_center_sk, cr_catalog_page_sk
),
joined AS (
    SELECT
        cc.cc_market_manager AS market_manager,
        cc.cc_mkt_id AS mkt_id,
        cp.cp_department AS department,
        cp.cp_end_date_sk,
        ra.total_return_amount,
        ra.total_return_quantity,
        ra.return_cnt
    FROM returns_agg ra
    JOIN call_center cc
        ON ra.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON ra.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cc.cc_mkt_id IN (1, 3, 5)
      AND cp.cp_end_date_sk >= 2450904
      AND cc.cc_rec_start_date > DATE '2000-01-01'
)
SELECT
    market_manager,
    mkt_id,
    department,
    AVG(total_return_amount) AS avg_return_amount,
    SUM(total_return_quantity) AS sum_return_quantity,
    SUM(return_cnt) AS total_returns
FROM joined
GROUP BY market_manager, mkt_id, department
HAVING AVG(total_return_amount) > 1000
ORDER BY avg_return_amount DESC
LIMIT 100
