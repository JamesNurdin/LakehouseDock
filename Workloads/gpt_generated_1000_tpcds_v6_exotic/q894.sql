WITH
    item_dim AS (
        SELECT i_item_sk,
               i_item_id,
               i_product_name,
               i_category
        FROM item
    ),
    store_sales_fact AS (
        SELECT ss.ss_item_sk,
               SUM(ss.ss_net_profit)                              AS store_net_profit,
               SUM(ss.ss_ext_sales_price)                         AS store_sales_amount,
               COUNT(*)                                            AS store_txn_cnt
        FROM store_sales ss
        JOIN store_returns sr
              ON sr.sr_ticket_number = ss.ss_ticket_number
             AND sr.sr_item_sk = ss.ss_item_sk
        JOIN reason r
              ON sr.sr_reason_sk = r.r_reason_sk
        JOIN customer_address ca_ref
              ON ss.ss_addr_sk = ca_ref.ca_address_sk
        JOIN customer_demographics cd_ref
              ON ss.ss_cdemo_sk = cd_ref.cd_demo_sk
        WHERE ca_ref.ca_state = 'CA'
          AND cd_ref.cd_gender = 'M'
        GROUP BY ss.ss_item_sk
    ),
    web_sales_fact AS (
        SELECT ws.ws_item_sk,
               SUM(ws.ws_net_profit)                              AS web_net_profit,
               SUM(ws.ws_ext_sales_price)                         AS web_sales_amount,
               COUNT(*)                                            AS web_txn_cnt
        FROM web_sales ws
        JOIN warehouse w
              ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN customer_address ca_ship
              ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
        JOIN customer_demographics cd_ship
              ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        GROUP BY ws.ws_item_sk
    ),
    catalog_returns_fact AS (
        SELECT cr.cr_item_sk,
               SUM(cr.cr_net_loss)                        AS catalog_net_loss,
               SUM(cr.cr_return_amount)                   AS catalog_return_amount
        FROM catalog_returns cr
        JOIN customer_address ca_refunded
              ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
        JOIN customer_demographics cd_refunded
              ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        JOIN customer_address ca_returning
              ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
        JOIN customer_demographics cd_returning
              ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
        JOIN warehouse w
              ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r
              ON cr.cr_reason_sk = r.r_reason_sk
        GROUP BY cr.cr_item_sk
    ),
    store_returns_fact AS (
        SELECT sr.sr_item_sk,
               SUM(sr.sr_net_loss)                       AS store_return_net_loss,
               SUM(sr.sr_return_amt)                     AS store_return_amount
        FROM store_returns sr
        JOIN reason r
              ON sr.sr_reason_sk = r.r_reason_sk
        GROUP BY sr.sr_item_sk
    ),
    inventory_fact AS (
        SELECT inv.inv_item_sk,
               SUM(inv.inv_quantity_on_hand) AS total_on_hand
        FROM inventory inv
        GROUP BY inv.inv_item_sk
        HAVING SUM(inv.inv_quantity_on_hand) > 500
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    COALESCE(ssf.store_net_profit, 0)        AS store_net_profit,
    COALESCE(wsf.web_net_profit, 0)          AS web_net_profit,
    COALESCE(crf.catalog_net_loss, 0)        AS catalog_return_loss,
    COALESCE(srf.store_return_net_loss, 0)   AS store_return_loss,
    invf.total_on_hand,
    ROW_NUMBER() OVER (
        PARTITION BY i.i_category
        ORDER BY (COALESCE(ssf.store_net_profit, 0) + COALESCE(wsf.web_net_profit, 0)) DESC
    )                                        AS category_rank
FROM item_dim i
LEFT JOIN store_sales_fact ssf
       ON ssf.ss_item_sk = i.i_item_sk
LEFT JOIN web_sales_fact wsf
       ON wsf.ws_item_sk = i.i_item_sk
LEFT JOIN catalog_returns_fact crf
       ON crf.cr_item_sk = i.i_item_sk
LEFT JOIN store_returns_fact srf
       ON srf.sr_item_sk = i.i_item_sk
LEFT JOIN inventory_fact invf
       ON invf.inv_item_sk = i.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM inventory inv_chk
    WHERE inv_chk.inv_item_sk = i.i_item_sk
      AND inv_chk.inv_quantity_on_hand > 200
)
ORDER BY store_net_profit DESC
LIMIT 100
