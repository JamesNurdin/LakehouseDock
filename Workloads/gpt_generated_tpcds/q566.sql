WITH combined AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        cc.cc_call_center_id AS entity_id,
        cc.cc_name AS entity_name,
        'call_center' AS entity_type,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, cc.cc_call_center_id, cc.cc_name

    UNION ALL

    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        wp.wp_web_page_id AS entity_id,
        wp.wp_type AS entity_name,
        'web_page' AS entity_type,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        CAST(NULL AS decimal(7,2)) AS total_return_amount,
        CAST(NULL AS decimal(7,2)) AS total_return_loss
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq, wp.wp_web_page_id, wp.wp_type
)
SELECT
    entity_type,
    entity_id,
    entity_name,
    d_year,
    month_seq,
    total_net_paid,
    total_net_profit,
    total_return_amount,
    total_return_loss,
    ROW_NUMBER() OVER (PARTITION BY entity_type ORDER BY total_net_paid DESC) AS revenue_rank
FROM combined
ORDER BY entity_type, revenue_rank
