WITH catalog_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        sm.sm_type,
        s.s_store_sk,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_return_quantity) AS catalog_return_qty,
        SUM(cr.cr_net_loss) AS catalog_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq, sm.sm_type, s.s_store_sk
),
store_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_return_quantity) AS store_return_qty,
        SUM(sr.sr_net_loss) AS store_net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    GROUP BY d.d_year, d.d_month_seq, s.s_store_sk
)
SELECT
    ca.d_year,
    ca.d_month_seq,
    st.s_store_name,
    ca.sm_type,
    ca.catalog_return_amount,
    sa.store_return_amount,
    ca.catalog_return_qty,
    sa.store_return_qty,
    ca.catalog_net_loss,
    sa.store_net_loss,
    CASE
        WHEN sa.store_net_loss = 0 THEN NULL
        ELSE ca.catalog_net_loss / sa.store_net_loss
    END AS loss_ratio,
    ROW_NUMBER() OVER (PARTITION BY ca.d_year, ca.d_month_seq ORDER BY ca.catalog_return_amount DESC) AS rn
FROM catalog_agg ca
JOIN store_agg sa
    ON ca.d_year = sa.d_year
    AND ca.d_month_seq = sa.d_month_seq
    AND ca.s_store_sk = sa.s_store_sk
JOIN store st
    ON st.s_store_sk = ca.s_store_sk
WHERE ca.d_year = 2020
ORDER BY ca.catalog_return_amount DESC
LIMIT 50
