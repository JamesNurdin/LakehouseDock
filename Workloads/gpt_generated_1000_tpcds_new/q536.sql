WITH
    -- Aggregate catalog returns by reason and time (pre‑aggregation before the big join)
    cat_agg AS (
        SELECT
            cr_reason_sk,
            cr_returned_time_sk,
            SUM(cr_return_amount)               AS total_cr_amount,
            COUNT(DISTINCT cr_order_number)      AS distinct_cr_orders
        FROM catalog_returns
        GROUP BY cr_reason_sk, cr_returned_time_sk
    ),
    -- Aggregate store returns by reason, store and time
    store_agg AS (
        SELECT
            sr_store_sk,
            sr_reason_sk,
            sr_return_time_sk,
            SUM(sr_return_amt)               AS total_sr_amount,
            COUNT(DISTINCT sr_ticket_number) AS distinct_sr_tickets
        FROM store_returns
        GROUP BY sr_store_sk, sr_reason_sk, sr_return_time_sk
    ),
    -- Aggregate web returns by reason and time
    web_agg AS (
        SELECT
            wr_reason_sk,
            wr_returned_time_sk,
            SUM(wr_return_amt)               AS total_wr_amount,
            COUNT(DISTINCT wr_order_number)  AS distinct_wr_orders
        FROM web_returns
        GROUP BY wr_reason_sk, wr_returned_time_sk
    ),
    -- Reasons that appear in catalog returns but not in store returns (EXCEPT example)
    diff_reason AS (
        SELECT cr_reason_sk AS reason_sk FROM catalog_returns
        EXCEPT
        SELECT sr_reason_sk      FROM store_returns
    ),
    -- First branch of the UNION – works from the catalog side
    branch_cat AS (
        SELECT
            ca.cr_reason_sk                        AS reason_sk,
            r_cat.r_reason_desc,
            ca.total_cr_amount,
            ca.distinct_cr_orders,
            cc.cc_name,
            sm.sm_carrier,
            w.w_city,
            td.t_hour,
            st.s_store_name,
            sr.total_sr_amount,
            sr.distinct_sr_tickets,
            wr.total_wr_amount,
            wr.distinct_wr_orders,
            la.store_qty_lateral
        FROM cat_agg ca
        JOIN catalog_returns cr
            ON ca.cr_reason_sk = cr.cr_reason_sk
           AND ca.cr_returned_time_sk = cr.cr_returned_time_sk
        JOIN reason r_cat
            ON cr.cr_reason_sk = r_cat.r_reason_sk
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim td
            ON cr.cr_returned_time_sk = td.t_time_sk
        LEFT JOIN store_agg sr
            ON r_cat.r_reason_sk = sr.sr_reason_sk
        LEFT JOIN store st
            ON sr.sr_store_sk = st.s_store_sk
        LEFT JOIN web_agg wr
            ON r_cat.r_reason_sk = wr.wr_reason_sk
        LEFT JOIN LATERAL (
            SELECT SUM(sr2.sr_return_quantity) AS store_qty_lateral
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = st.s_store_sk
              AND sr2.sr_return_time_sk = td.t_time_sk
        ) la ON TRUE
        WHERE EXISTS (
            SELECT 1 FROM call_center cc2
            WHERE cc2.cc_division = cc.cc_division
              AND cc2.cc_state = 'CA'
        )
    ),
    -- Second branch of the UNION – works from the store side using a different alias for REASON and TIME_DIM
    branch_store AS (
        SELECT
            sr.sr_reason_sk                         AS reason_sk,
            r_st.r_reason_desc,
            CAST(NULL AS decimal(7,2))               AS total_cr_amount,
            CAST(NULL AS integer)                    AS distinct_cr_orders,
            CAST(NULL AS varchar)                    AS cc_name,
            CAST(NULL AS varchar)                    AS sm_carrier,
            CAST(NULL AS varchar)                    AS w_city,
            td2.t_hour,
            st.s_store_name,
            sr.total_sr_amount,
            sr.distinct_sr_tickets,
            CAST(NULL AS decimal(7,2))               AS total_wr_amount,
            CAST(NULL AS integer)                    AS distinct_wr_orders,
            CAST(NULL AS bigint)                     AS store_qty_lateral
        FROM store_agg sr
        JOIN store st
            ON sr.sr_store_sk = st.s_store_sk
        JOIN reason r_st
            ON sr.sr_reason_sk = r_st.r_reason_sk
        JOIN time_dim td2
            ON sr.sr_return_time_sk = td2.t_time_sk
        -- a harmless LATERAL join just to keep the shape similar to the first branch
        LEFT JOIN LATERAL (SELECT 1) la ON TRUE
    )
SELECT
    u.reason_sk,
    u.r_reason_desc,
    SUM(u.total_cr_amount)               AS sum_cr_amount,
    COUNT(DISTINCT u.distinct_cr_orders) AS cnt_dist_cr_orders,
    SUM(u.total_sr_amount)               AS sum_sr_amount,
    COUNT(DISTINCT u.distinct_sr_tickets) AS cnt_dist_sr_tickets,
    SUM(u.total_wr_amount)               AS sum_wr_amount,
    COUNT(DISTINCT u.distinct_wr_orders) AS cnt_dist_wr_orders,
    SUM(u.store_qty_lateral)             AS sum_store_qty
FROM (
    SELECT * FROM branch_cat
    UNION DISTINCT
    SELECT * FROM branch_store
) u
WHERE u.reason_sk IN (SELECT reason_sk FROM diff_reason)
GROUP BY GROUPING SETS (
    (u.reason_sk, u.r_reason_desc),
    (u.cc_name),
    ()
)
ORDER BY sum_cr_amount DESC
LIMIT 100
