WITH
    sampled_sr AS (
        SELECT *
        FROM store_returns
        TABLESAMPLE BERNOULLI (10)
    ),
    filtered_store AS (
        SELECT s_store_sk
        FROM store
        WHERE s_state = 'CA'
    ),
    sr_filtered AS (
        SELECT *
        FROM sampled_sr
        WHERE sr_store_sk IN (SELECT s_store_sk FROM filtered_store)
    ),
    store_part AS (
        SELECT
            s.s_store_name AS entity_name,
            r.r_reason_desc AS reason,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            ca.ca_state AS state,
            sr.sr_net_loss AS net_loss,
            sr.sr_return_quantity AS qty,
            NULL AS call_center_name
        FROM sr_filtered sr
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    ),
    catalog_part AS (
        SELECT
            cc.cc_name AS entity_name,
            r.r_reason_desc AS reason,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            ca.ca_state AS state,
            cr.cr_net_loss AS net_loss,
            cr.cr_return_quantity AS qty,
            cc.cc_name AS call_center_name
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        WHERE cr.cr_return_quantity > 0
          AND cr.cr_returned_date_sk BETWEEN 2450000 AND 2450100
          AND r.r_reason_id IN (
                SELECT r_reason_id
                FROM reason
                WHERE r_reason_desc LIKE '%damaged%'
          )
    ),
    web_part AS (
        SELECT
            NULL AS entity_name,
            r.r_reason_desc AS reason,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            ca.ca_state AS state,
            wr.wr_net_loss AS net_loss,
            wr.wr_return_quantity AS qty,
            NULL AS call_center_name
        FROM web_returns wr
        JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2450100
          AND wr.wr_return_quantity > 1
          AND ca.ca_state = 'NY'
    ),
    combined_raw AS (
        SELECT * FROM store_part
        UNION
        SELECT * FROM catalog_part
        UNION
        SELECT * FROM web_part
    ),
    agg AS (
        SELECT
            entity_name,
            reason,
            state,
            ib_lower_bound,
            ib_upper_bound,
            SUM(net_loss) AS total_net_loss,
            SUM(qty) AS total_qty,
            AVG(net_loss) AS avg_net_loss
        FROM combined_raw
        GROUP BY entity_name, reason, state, ib_lower_bound, ib_upper_bound
        HAVING SUM(qty) > 10
    ),
    excluded_entities AS (
        SELECT s_store_name AS entity_name
        FROM store
        WHERE s_number_employees > 500
    ),
    diff_entities AS (
        SELECT entity_name FROM agg
        EXCEPT
        SELECT entity_name FROM excluded_entities
    ),
    final AS (
        SELECT
            a.entity_name,
            a.reason,
            a.state,
            a.ib_lower_bound,
            a.ib_upper_bound,
            a.total_net_loss,
            a.total_qty,
            a.avg_net_loss,
            RANK() OVER (PARTITION BY a.state ORDER BY a.total_net_loss DESC) AS loss_rank
        FROM agg a
        WHERE a.entity_name IN (SELECT entity_name FROM diff_entities)
          AND EXISTS (
                SELECT 1
                FROM store s
                WHERE s.s_store_name = a.entity_name
                  AND s.s_state = 'CA'
          )
    )
SELECT *
FROM final
ORDER BY state, loss_rank
LIMIT 100
