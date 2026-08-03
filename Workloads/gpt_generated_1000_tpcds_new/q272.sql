WITH joined_sales_returns AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        wr.wr_net_loss
    FROM web_sales ws
    JOIN web_returns wr
      ON ws.ws_item_sk = wr.wr_item_sk
     AND ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_web_site_sk IN (15, 51, 5)
      AND ws.ws_ext_sales_price > 0
),
sales_agg AS (
    SELECT
        CAST(ws_web_site_sk AS VARCHAR)               AS key_id,
        CASE
            WHEN regexp_like(CAST(ws_order_number AS VARCHAR), '^1[0-9]{5}$') THEN 'high_order'
            ELSE 'normal_order'
        END                                          AS order_type,
        SUM(ws_ext_sales_price)                       AS total_amount,
        COUNT(*)                                      AS transaction_count
    FROM joined_sales_returns
    GROUP BY
        CAST(ws_web_site_sk AS VARCHAR),
        CASE
            WHEN regexp_like(CAST(ws_order_number AS VARCHAR), '^1[0-9]{5}$') THEN 'high_order'
            ELSE 'normal_order'
        END
),
returns_agg AS (
    SELECT
        CAST(wr_returning_addr_sk AS VARCHAR)          AS key_id,
        CASE
            WHEN regexp_like(CAST(wr_refunded_customer_sk AS VARCHAR), '^2[0-9]{6}$') THEN 'ref_high'
            ELSE 'ref_other'
        END                                          AS order_type,
        SUM(wr_net_loss)                              AS total_amount,
        COUNT(*)                                      AS transaction_count
    FROM web_returns
    WHERE wr_net_loss > 0
      AND regexp_like(CAST(wr_refunded_customer_sk AS VARCHAR), '^[0-9]+$')
    GROUP BY
        CAST(wr_returning_addr_sk AS VARCHAR),
        CASE
            WHEN regexp_like(CAST(wr_refunded_customer_sk AS VARCHAR), '^2[0-9]{6}$') THEN 'ref_high'
            ELSE 'ref_other'
        END
)
SELECT key_id, total_amount, transaction_count, order_type
FROM sales_agg
UNION DISTINCT
SELECT key_id, total_amount, transaction_count, order_type
FROM returns_agg
ORDER BY total_amount DESC
LIMIT 100
