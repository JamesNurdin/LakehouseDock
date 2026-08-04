WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_ship_mode_sk,
        cs_catalog_page_sk,
        SUM(cs_net_paid) AS total_sales,
        SUM(cs_net_profit) AS total_profit
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_order_number NOT IN (
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_return_amount > 5000
    )
    GROUP BY cs_call_center_sk, cs_ship_mode_sk, cs_catalog_page_sk
),
returns_agg AS (
    SELECT
        cr_call_center_sk,
        cr_ship_mode_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_returns
    FROM catalog_returns
    WHERE cr_return_amount > 100
    GROUP BY cr_call_center_sk, cr_ship_mode_sk, cr_reason_sk
),
store_ret_agg AS (
    SELECT
        sr_store_sk,
        sr_reason_sk,
        SUM(sr_return_amt) AS total_store_returns
    FROM store_returns
    WHERE sr_return_amt > 50
    GROUP BY sr_store_sk, sr_reason_sk
)
SELECT
    cc.cc_name                AS call_center_name,
    cp.cp_catalog_page_number AS catalog_page_number,
    sm.sm_ship_mode_id        AS ship_mode_id,
    r.r_reason_desc           AS reason_desc,
    s.s_store_name            AS store_name,
    sa.total_sales,
    sa.total_profit,
    ra.total_returns,
    sta.total_store_returns,
    RANK() OVER (ORDER BY sa.total_sales DESC)                                     AS sales_rank,
    LAG(sa.total_sales) OVER (PARTITION BY cc.cc_name ORDER BY sa.total_sales DESC) AS previous_sales
FROM sales_agg sa
JOIN call_center cc   ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm      ON sa.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN catalog_page cp   ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN returns_agg ra ON ra.cr_call_center_sk = cc.cc_call_center_sk
                        AND ra.cr_ship_mode_sk   = sm.sm_ship_mode_sk
LEFT JOIN store_ret_agg sta ON 1 = 1   -- keep row for join to store and reason
JOIN store s           ON sta.sr_store_sk = s.s_store_sk
LEFT JOIN reason r    ON r.r_reason_sk = COALESCE(ra.cr_reason_sk, sta.sr_reason_sk)
WHERE
    cc.cc_employees > 100
    AND sm.sm_contract = 'A5BYO1qH8HGTTN'
    AND cp.cp_department = 'Electronics'
    AND s.s_state = 'CA'
    AND sa.total_sales > 10000
    AND ra.total_returns > 5000

UNION DISTINCT

SELECT
    cc.cc_name,
    cp.cp_catalog_page_number,
    sm.sm_ship_mode_id,
    r.r_reason_desc,
    s.s_store_name,
    sa.total_sales,
    sa.total_profit,
    ra.total_returns,
    sta.total_store_returns,
    RANK() OVER (ORDER BY sa.total_sales DESC)                                     AS sales_rank,
    LAG(sa.total_sales) OVER (PARTITION BY cc.cc_name ORDER BY sa.total_sales DESC) AS previous_sales
FROM sales_agg sa
JOIN call_center cc   ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm      ON sa.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN catalog_page cp   ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN returns_agg ra ON ra.cr_call_center_sk = cc.cc_call_center_sk
                        AND ra.cr_ship_mode_sk   = sm.sm_ship_mode_sk
LEFT JOIN store_ret_agg sta ON 1 = 1   -- keep columns; rows may be null
LEFT JOIN store s           ON sta.sr_store_sk = s.s_store_sk
LEFT JOIN reason r        ON r.r_reason_sk = COALESCE(ra.cr_reason_sk, sta.sr_reason_sk)
WHERE
    cc.cc_employees > 200
    AND sm.sm_contract = 'YvxVaJI10'
    AND cp.cp_department = 'Books'
    AND s.s_state = 'NY'
    AND sa.total_sales > 20000
    AND ra.total_returns > 10000

ORDER BY sales_rank
LIMIT 100
