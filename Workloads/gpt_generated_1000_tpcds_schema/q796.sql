WITH
    -- expand the comma‑separated hours string from call_center
    hours_expanded AS (
        SELECT
            cc.cc_call_center_sk,
            TRIM(hour_part) AS hour_part
        FROM call_center cc
        CROSS JOIN UNNEST(split(cc.cc_hours, ',')) AS t(hour_part)
    ),
    -- store side aggregation (sales + returns)
    store_agg AS (
        SELECT
            st.s_store_sk,
            st.s_store_name,
            d.d_year,
            SUM(ss.ss_net_profit)                         AS profit_store,
            SUM(COALESCE(sr.sr_net_loss, 0))               AS loss_store
        FROM store_sales ss
        JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN store st            ON ss.ss_store_sk = st.s_store_sk
        LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        LEFT JOIN reason r        ON sr.sr_reason_sk = r.r_reason_sk
        GROUP BY st.s_store_sk, st.s_store_name, d.d_year
    ),
    -- catalog side aggregation (sales + returns) and hour parts from call_center
    catalog_agg AS (
        SELECT
            w.w_warehouse_sk,
            w.w_warehouse_name,
            d.d_year,
            SUM(cs.cs_net_paid)                           AS net_paid_catalog,
            SUM(COALESCE(cr.cr_net_loss, 0))               AS loss_catalog,
            COUNT(DISTINCT he.hour_part)                  AS hour_parts_cnt
        FROM catalog_sales cs
        JOIN date_dim d          ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN warehouse w         ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
        LEFT JOIN reason r            ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN hours_expanded he   ON cc.cc_call_center_sk = he.cc_call_center_sk
        GROUP BY w.w_warehouse_sk, w.w_warehouse_name, d.d_year
    ),
    -- full outer join of the two aggregations
    full_combined AS (
        SELECT
            COALESCE(sa.s_store_sk, ca.w_warehouse_sk) AS entity_sk,
            COALESCE(sa.s_store_name, ca.w_warehouse_name) AS entity_name,
            COALESCE(sa.d_year, ca.d_year)                 AS year,
            sa.profit_store,
            sa.loss_store,
            ca.net_paid_catalog,
            ca.loss_catalog,
            ca.hour_parts_cnt
        FROM store_agg sa
        FULL OUTER JOIN catalog_agg ca
            ON sa.s_store_sk = ca.w_warehouse_sk
            AND sa.d_year = ca.d_year
    ),
    -- anti‑semi‑join: exclude entities that belong to a closed store
    filtered AS (
        SELECT *
        FROM full_combined fc
        WHERE fc.entity_sk NOT IN (
            SELECT s.s_store_sk
            FROM store s
            WHERE s.s_closed_date_sk IS NOT NULL
        )
    ),
    -- intersect ticket numbers that appear in both sales and returns
    common_tickets AS (
        SELECT ss_ticket_number
        FROM store_sales
        INTERSECT
        SELECT sr_ticket_number
        FROM store_returns
    ),
    -- orders that exist in sales but not in returns
    unique_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
    ),
    -- union of two year sets (to be used for a filter later)
    years_union AS (
        SELECT d_year FROM date_dim WHERE d_year = 2000
        UNION
        SELECT d_year FROM date_dim WHERE d_year = 2001
    ),
    -- final aggregation pulling everything together
    final AS (
        SELECT
            f.entity_sk,
            f.entity_name,
            f.year,
            f.profit_store,
            f.loss_store,
            f.net_paid_catalog,
            f.loss_catalog,
            f.hour_parts_cnt,
            COUNT(DISTINCT ct.ss_ticket_number) AS common_ticket_cnt,
            COUNT(DISTINCT uo.cs_order_number)   AS unique_order_cnt
        FROM filtered f
        LEFT JOIN common_tickets ct ON 1 = 1   -- cross‑join for counting
        LEFT JOIN unique_orders uo   ON 1 = 1
        WHERE f.year IN (SELECT d_year FROM years_union)
        GROUP BY
            f.entity_sk,
            f.entity_name,
            f.year,
            f.profit_store,
            f.loss_store,
            f.net_paid_catalog,
            f.loss_catalog,
            f.hour_parts_cnt
    )
SELECT *
FROM final
ORDER BY year DESC, profit_store DESC NULLS LAST
LIMIT 100
