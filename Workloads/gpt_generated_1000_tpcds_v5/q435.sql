WITH web_sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_net_paid) AS amount,
        'Web' AS source
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
      AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
              AND wp.wp_type = 'article'
        )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
store_returns_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(sr.sr_refunded_cash + sr.sr_store_credit) AS amount,
        'Store' AS source
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE sr.sr_refunded_cash > 100
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
combined AS (
    SELECT * FROM web_sales_agg
    UNION ALL
    SELECT * FROM store_returns_agg
)
SELECT
    c.i_item_id,
    c.i_product_name,
    c.source,
    c.amount,
    CASE WHEN c.source = 'Web' THEN c.amount ELSE -c.amount END AS net_effect,
    (
        SELECT AVG(i2.i_wholesale_cost)
        FROM item i2
        WHERE i2.i_category = i.i_category
    ) AS avg_wholesale_cost_in_category
FROM combined c
JOIN item i ON c.i_item_sk = i.i_item_sk
ORDER BY net_effect DESC
LIMIT 100
