WITH
    store_agg AS (
        SELECT
            i.i_item_id AS i_item_id,
            'store' AS source_type,
            s.s_store_id AS store_id,
            SUM(sr.sr_return_quantity) AS total_return_qty,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(*) AS num_returns,
            cd.cd_credit_rating,
            ca.ca_state,
            i.i_current_price
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
        WHERE sr.sr_return_quantity > 0
          AND i.i_current_price BETWEEN 10 AND 500
          AND ca.ca_state IN ('CA', 'NY', 'TX')
          AND cd.cd_credit_rating = 'Good'
          AND sr.sr_returned_date_sk BETWEEN 2451080 AND 2451085
          AND inv.inv_quantity_on_hand >= 100
          AND NOT EXISTS (
                SELECT 1 FROM promotion p2
                WHERE p2.p_item_sk = i.i_item_sk
                  AND p2.p_discount_active = 'Y'
            )
        GROUP BY i.i_item_id, s.s_store_id, cd.cd_credit_rating, ca.ca_state, i.i_current_price
        HAVING SUM(sr.sr_return_quantity) > 10
    ),
    catalog_agg AS (
        SELECT
            i.i_item_id AS i_item_id,
            'catalog' AS source_type,
            CAST(NULL AS varchar) AS store_id,
            SUM(cr.cr_return_quantity) AS total_return_qty,
            SUM(cr.cr_net_loss) AS total_net_loss,
            COUNT(*) AS num_returns,
            cd.cd_credit_rating,
            ca.ca_state,
            i.i_current_price
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
        WHERE cr.cr_return_quantity > 0
          AND i.i_current_price > 20
          AND cd.cd_education_status = 'College'
          AND ca.ca_city LIKE 'San%'
          AND cr.cr_returned_date_sk BETWEEN 2451080 AND 2451085
          AND inv.inv_quantity_on_hand >= 100
          AND NOT EXISTS (
                SELECT 1 FROM promotion p2
                WHERE p2.p_item_sk = i.i_item_sk
                  AND p2.p_discount_active = 'Y'
            )
        GROUP BY i.i_item_id, cd.cd_credit_rating, ca.ca_state, i.i_current_price
        HAVING SUM(cr.cr_return_quantity) > 5
    ),
    web_agg AS (
        SELECT
            i.i_item_id AS i_item_id,
            'web' AS source_type,
            CAST(NULL AS varchar) AS store_id,
            SUM(wr.wr_return_quantity) AS total_return_qty,
            SUM(wr.wr_net_loss) AS total_net_loss,
            COUNT(*) AS num_returns,
            cd.cd_credit_rating,
            ca.ca_state,
            i.i_current_price
        FROM web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
        WHERE wr.wr_return_quantity > 0
          AND i.i_current_price < 400
          AND cd.cd_gender = 'M'
          AND ca.ca_state = 'CA'
          AND wp.wp_type = 'detail'
          AND wr.wr_returned_date_sk BETWEEN 2451080 AND 2451085
          AND inv.inv_quantity_on_hand >= 100
          AND NOT EXISTS (
                SELECT 1 FROM promotion p2
                WHERE p2.p_item_sk = i.i_item_sk
                  AND p2.p_discount_active = 'Y'
            )
        GROUP BY i.i_item_id, cd.cd_credit_rating, ca.ca_state, i.i_current_price
        HAVING SUM(wr.wr_return_quantity) > 5
    ),
    combined_returns AS (
        SELECT * FROM store_agg
        UNION ALL
        SELECT * FROM catalog_agg
        UNION ALL
        SELECT * FROM web_agg
    ),
    final_agg AS (
        SELECT
            i_item_id,
            SUM(total_return_qty) AS sum_return_qty,
            SUM(total_net_loss) AS sum_net_loss,
            AVG(total_net_loss) AS avg_net_loss,
            COUNT(*) AS source_count
        FROM combined_returns
        GROUP BY i_item_id
        HAVING SUM(total_return_qty) > 20
    )
SELECT
    i_item_id,
    sum_return_qty,
    sum_net_loss,
    avg_net_loss,
    source_count
FROM final_agg
ORDER BY sum_net_loss DESC
LIMIT 100
