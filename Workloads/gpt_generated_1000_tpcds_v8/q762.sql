WITH
    cr_agg AS (
        SELECT
            cr_item_sk,
            cr_returned_date_sk,
            SUM(cr_return_amount) AS total_return_amount,
            COUNT(*) AS return_cnt
        FROM catalog_returns
        WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451000
          AND cr_return_quantity > 0
        GROUP BY cr_item_sk, cr_returned_date_sk
    ),
    ws_sample AS (
        SELECT *
        FROM web_sales TABLESAMPLE BERNOULLI (10)
        WHERE ws_sold_date_sk BETWEEN 2450900 AND 2451000
          AND ws_quantity > 1
    ),
    except_orders AS (
        SELECT ws_order_number
        FROM ws_sample
        EXCEPT
        SELECT cr_order_number
        FROM catalog_returns
        WHERE cr_returned_date_sk BETWEEN 2450900 AND 2451000
    ),
    union_data AS (
        SELECT
            i.i_item_id,
            i.i_brand,
            ws.ws_order_number,
            ws.ws_net_paid,
            ws.ws_sold_date_sk AS date_sk,
            NULL AS cr_order_number,
            NULL AS total_return_amount,
            NULL AS cc_call_center_id,
            ca.ca_state,
            p.p_promo_name,
            (
                SELECT COUNT(*)
                FROM catalog_returns cr_sub
                WHERE cr_sub.cr_item_sk = i.i_item_sk
            ) AS total_returns_for_item
        FROM ws_sample ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
                           AND p.p_item_sk = i.i_item_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
        WHERE p.p_channel_tv = 'N'
          AND i.i_class_id IN (1, 12)
        UNION DISTINCT
        SELECT
            i.i_item_id,
            i.i_brand,
            NULL AS ws_order_number,
            NULL AS ws_net_paid,
            cr.cr_returned_date_sk AS date_sk,
            cr.cr_order_number AS cr_order_number,
            agg.total_return_amount,
            cc.cc_call_center_id,
            ca.ca_state,
            NULL AS promo_name,
            (
                SELECT COUNT(*)
                FROM catalog_returns cr_sub
                WHERE cr_sub.cr_item_sk = i.i_item_sk
            ) AS total_returns_for_item
        FROM catalog_returns cr
        JOIN cr_agg agg ON cr.cr_item_sk = agg.cr_item_sk
                         AND cr.cr_returned_date_sk = agg.cr_returned_date_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE cp.cp_department = 'Electronics'
          AND cc.cc_state = 'CA'
    )
SELECT
    date_sk,
    COUNT(DISTINCT ws_order_number) AS distinct_ws_orders,
    COUNT(DISTINCT cr_order_number) AS distinct_cr_orders,
    SUM(ws_net_paid) AS total_ws_net_paid,
    SUM(total_return_amount) AS total_cr_return_amount,
    MIN(ws_net_paid) AS min_ws_net_paid,
    MAX(total_return_amount) AS max_cr_return_amount,
    AVG(total_returns_for_item) AS avg_returns_per_item,
    (SELECT COUNT(*) FROM except_orders) AS except_order_count
FROM union_data
GROUP BY date_sk
ORDER BY date_sk DESC
LIMIT 100
