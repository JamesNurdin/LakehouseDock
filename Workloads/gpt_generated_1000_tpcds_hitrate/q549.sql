WITH
    catalog_events AS (
        SELECT
            cs.cs_order_number AS order_number,
            d.d_date AS event_date,
            i.i_item_id AS item_id,
            i.i_product_name AS product_name,
            cs.cs_quantity AS quantity,
            cs.cs_net_paid AS monetary_amount,
            CASE
                WHEN cs.cs_ship_mode_sk = 4 THEN 'Standard'
                WHEN cs.cs_ship_mode_sk = 6 THEN 'Express'
                ELSE 'Other'
            END AS category_desc,
            (
                SELECT SUM(cs2.cs_ext_sales_price)
                FROM catalog_sales cs2
                WHERE cs2.cs_item_sk = cs.cs_item_sk
            ) AS total_related_amount,
            'Catalog' AS source_type
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        WHERE cs.cs_quantity > 1
          AND d.d_year = 2020
          AND cs.cs_order_number NOT IN (
              SELECT sr_ticket_number
              FROM store_returns
              WHERE sr_return_quantity > 0
          )
    ),
    store_return_events AS (
        SELECT
            sr.sr_ticket_number AS order_number,
            d.d_date AS event_date,
            i.i_item_id AS item_id,
            i.i_product_name AS product_name,
            sr.sr_return_quantity AS quantity,
            sr.sr_net_loss AS monetary_amount,
            CASE
                WHEN sr.sr_return_quantity > 5 THEN 'High'
                ELSE 'Low'
            END AS category_desc,
            (
                SELECT SUM(sr2.sr_return_amt)
                FROM store_returns sr2
                WHERE sr2.sr_item_sk = sr.sr_item_sk
            ) AS total_related_amount,
            'StoreReturn' AS source_type
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        WHERE sr.sr_return_quantity > 0
          AND d.d_year = 2020
    ),
    union_events AS (
        SELECT * FROM catalog_events
        UNION ALL
        SELECT * FROM store_return_events
    ),
    cross_set AS (
        SELECT d.d_date, v.seq
        FROM (SELECT d_date FROM date_dim WHERE d_date = DATE '2020-01-01') d
        CROSS JOIN (VALUES 1, 2) AS v(seq)
    )
SELECT
    ue.order_number,
    ue.event_date,
    ue.item_id,
    ue.product_name,
    ue.quantity,
    ue.monetary_amount,
    ue.category_desc,
    ue.total_related_amount,
    cs.seq AS seq_number
FROM union_events ue
CROSS JOIN cross_set cs
ORDER BY ue.event_date DESC, ue.order_number
LIMIT 100
