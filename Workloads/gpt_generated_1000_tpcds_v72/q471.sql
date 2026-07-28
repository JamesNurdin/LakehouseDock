WITH date_filter AS (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    ),
    returns_agg AS (
        SELECT
            i.i_item_id,
            i.i_item_desc,
            'return' AS metric_type,
            SUM(cr.cr_return_amount) AS metric_value,
            COUNT(DISTINCT cr.cr_order_number) AS order_cnt
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE d.d_date_sk IN (SELECT d_date_sk FROM date_filter)
          AND cp.cp_department = 'Electronics'
        GROUP BY i.i_item_id, i.i_item_desc
        HAVING SUM(cr.cr_return_amount) > 500
    ),
    promo_agg AS (
        SELECT
            i.i_item_id,
            i.i_item_desc,
            'promo' AS metric_type,
            SUM(p.p_cost) AS metric_value,
            COUNT(DISTINCT p.p_promo_id) AS promo_cnt
        FROM promotion p
        JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
        JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
        JOIN item i ON p.p_item_sk = i.i_item_sk
        WHERE d_start.d_date_sk IN (SELECT d_date_sk FROM date_filter)
          AND d_end.d_date_sk IN (SELECT d_date_sk FROM date_filter)
          AND p.p_channel_event = 'N'
        GROUP BY i.i_item_id, i.i_item_desc
        HAVING SUM(p.p_cost) > 200
    )
SELECT DISTINCT
    item_id,
    item_desc,
    metric_type,
    metric_value,
    CASE WHEN metric_type = 'return' THEN order_cnt ELSE promo_cnt END AS count_indicator
FROM (
        SELECT
            i_item_id AS item_id,
            i_item_desc AS item_desc,
            metric_type,
            metric_value,
            order_cnt,
            NULL AS promo_cnt
        FROM returns_agg
        UNION ALL
        SELECT
            i_item_id AS item_id,
            i_item_desc AS item_desc,
            metric_type,
            metric_value,
            NULL AS order_cnt,
            promo_cnt
        FROM promo_agg
    ) combined
ORDER BY metric_value DESC
LIMIT 100
