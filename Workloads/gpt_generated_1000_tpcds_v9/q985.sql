WITH
    d_cr AS (
        SELECT d_date_sk, d_year, d_month_seq, d_date
        FROM date_dim
    ),
    d_wr AS (
        SELECT d_date_sk, d_year, d_month_seq, d_date
        FROM date_dim
    ),
    d_i AS (
        SELECT d_date_sk, d_date
        FROM date_dim
    ),
    d_s AS (
        SELECT d_date_sk, d_date
        FROM date_dim
    ),
    d_cc_open AS (
        SELECT d_date_sk, d_date
        FROM date_dim
    ),
    d_cc_closed AS (
        SELECT d_date_sk, d_date
        FROM date_dim
    ),
    d_ws_open AS (
        SELECT d_date_sk, d_date
        FROM date_dim
    ),
    d_ws_close AS (
        SELECT d_date_sk, d_date
        FROM date_dim
    ),
    rc_reason AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
    ),
    rw_reason AS (
        SELECT r_reason_sk, r_reason_desc
        FROM reason
    ),
    cr_joined AS (
        SELECT
            cr.cr_returned_date_sk,
            d_cr.d_year AS cr_year,
            d_cr.d_month_seq AS cr_month,
            cr.cr_return_amount,
            cr.cr_return_tax,
            cr.cr_return_amt_inc_tax,
            cr.cr_net_loss,
            cr.cr_order_number,
            cr.cr_reason_sk,
            rc_reason.r_reason_desc,
            cc.cc_name,
            d_cc_open.d_date AS cc_open_date,
            d_cc_closed.d_date AS cc_closed_date,
            ca_ref.ca_state AS refunded_state,
            ca_ret.ca_state AS returning_state
        FROM catalog_returns cr
        JOIN d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
        JOIN rc_reason ON cr.cr_reason_sk = rc_reason.r_reason_sk
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN d_cc_open ON cc.cc_open_date_sk = d_cc_open.d_date_sk
        LEFT JOIN d_cc_closed ON cc.cc_closed_date_sk = d_cc_closed.d_date_sk
        LEFT JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        LEFT JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
        WHERE NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = cr.cr_order_number
              AND cr2.cr_return_amount > cr.cr_return_amount
        )
    ),
    wr_joined AS (
        SELECT
            wr.wr_returned_date_sk,
            d_wr.d_year AS wr_year,
            d_wr.d_month_seq AS wr_month,
            wr.wr_return_amt,
            wr.wr_return_tax,
            wr.wr_return_amt_inc_tax,
            wr.wr_net_loss,
            wr.wr_order_number,
            wr.wr_reason_sk,
            rw_reason.r_reason_desc AS reason_desc,
            ca_wr_ref.ca_state AS refunded_state,
            ca_wr_ret.ca_state AS returning_state
        FROM web_returns wr
        JOIN d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        JOIN rw_reason ON wr.wr_reason_sk = rw_reason.r_reason_sk
        LEFT JOIN customer_address ca_wr_ref ON wr.wr_refunded_addr_sk = ca_wr_ref.ca_address_sk
        LEFT JOIN customer_address ca_wr_ret ON wr.wr_returning_addr_sk = ca_wr_ret.ca_address_sk
    ),
    store_joined AS (
        SELECT
            s.s_store_sk,
            s.s_store_name,
            s.s_state,
            d_s.d_date AS store_closed_date
        FROM store s
        LEFT JOIN d_s ON s.s_closed_date_sk = d_s.d_date_sk
    ),
    inventory_joined AS (
        SELECT
            i.inv_item_sk,
            i.inv_warehouse_sk,
            i.inv_quantity_on_hand,
            d_i.d_date AS inventory_date
        FROM inventory i
        JOIN d_i ON i.inv_date_sk = d_i.d_date_sk
    ),
    web_site_joined AS (
        SELECT
            ws.web_site_sk,
            ws.web_name,
            d_ws_open.d_date AS web_open_date,
            d_ws_close.d_date AS web_close_date
        FROM web_site ws
        LEFT JOIN d_ws_open ON ws.web_open_date_sk = d_ws_open.d_date_sk
        LEFT JOIN d_ws_close ON ws.web_close_date_sk = d_ws_close.d_date_sk
    ),
    returns_combined AS (
        SELECT
            cr_year AS year,
            cr_month AS month,
            cr_return_amount AS return_amount,
            cr_return_tax AS return_tax,
            cr_return_amt_inc_tax AS return_inc_tax,
            cr_net_loss AS net_loss,
            r_reason_desc AS reason_desc,
            cc_name AS call_center_name,
            refunded_state,
            returning_state,
            'catalog' AS return_type,
            cr_order_number AS order_number
        FROM cr_joined
        UNION ALL
        SELECT
            wr_year AS year,
            wr_month AS month,
            wr_return_amt AS return_amount,
            wr_return_tax AS return_tax,
            wr_return_amt_inc_tax AS return_inc_tax,
            wr_net_loss AS net_loss,
            reason_desc,
            NULL AS call_center_name,
            refunded_state,
            returning_state,
            'web' AS return_type,
            wr_order_number AS order_number
        FROM wr_joined
    ),
    aggregated AS (
        SELECT
            rc.year,
            rc.month,
            rc.reason_desc,
            COUNT(DISTINCT rc.order_number) AS distinct_orders,
            SUM(rc.return_amount) AS total_return_amount,
            SUM(rc.return_tax) AS total_return_tax,
            SUM(rc.return_inc_tax) AS total_return_inc_tax,
            SUM(rc.net_loss) AS total_net_loss,
            ROW_NUMBER() OVER (PARTITION BY rc.year ORDER BY SUM(rc.return_amount) DESC) AS month_rank,
            (
                SELECT AVG(i.inv_quantity_on_hand)
                FROM inventory_joined i
                WHERE EXTRACT(YEAR FROM i.inventory_date) = rc.year
                  AND EXTRACT(MONTH FROM i.inventory_date) = rc.month
            ) AS avg_inventory_qty
        FROM returns_combined rc
        GROUP BY rc.year, rc.month, rc.reason_desc
        HAVING SUM(rc.return_amount) > 5000
    ),
    store_inventory AS (
        SELECT
            sd.s_store_name,
            sd.store_closed_date,
            i.inv_quantity_on_hand,
            i.inventory_date
        FROM store_joined sd
        FULL OUTER JOIN inventory_joined i
            ON sd.store_closed_date = i.inventory_date
    )
SELECT
    agg.year,
    agg.month,
    agg.reason_desc,
    agg.total_return_amount,
    agg.total_return_tax,
    agg.total_return_inc_tax,
    agg.total_net_loss,
    agg.distinct_orders,
    agg.month_rank,
    agg.avg_inventory_qty,
    COALESCE(si.s_store_name, 'No Store') AS store_name,
    si.inv_quantity_on_hand,
    ws.web_name,
    ws.web_open_date,
    ws.web_close_date
FROM aggregated agg
LEFT JOIN store_inventory si
    ON agg.year = EXTRACT(YEAR FROM si.store_closed_date)
   AND agg.month = EXTRACT(MONTH FROM si.store_closed_date)
LEFT JOIN web_site_joined ws
    ON agg.year = EXTRACT(YEAR FROM ws.web_open_date)
   AND agg.month = EXTRACT(MONTH FROM ws.web_open_date)
ORDER BY agg.total_return_amount DESC
LIMIT 100
