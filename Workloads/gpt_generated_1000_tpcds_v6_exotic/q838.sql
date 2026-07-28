WITH agg_returns AS (
    SELECT
        cr_item_sk,
        cr_returned_date_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        MIN(cr_refunded_cdemo_sk) AS demo_sk,
        MIN(cr_refunded_addr_sk) AS addr_sk
    FROM catalog_returns
    WHERE cr_fee > 5.00
      AND cr_returned_date_sk BETWEEN 2450900 AND 2451200
      AND cr_return_quantity >= 1
    GROUP BY cr_item_sk, cr_returned_date_sk
)
SELECT DISTINCT
    i.i_item_id,
    i.i_brand,
    i.i_color,
    ar.total_return_amount,
    ws.ws_net_paid_inc_ship,
    RANK() OVER (PARTITION BY i.i_item_id ORDER BY ws.ws_net_paid_inc_ship DESC) AS profit_rank,
    CASE
        WHEN ws.ws_net_paid_inc_ship > 5000 THEN 'HIGH'
        WHEN ws.ws_net_paid_inc_ship BETWEEN 2000 AND 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM agg_returns ar
JOIN item i ON ar.cr_item_sk = i.i_item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN customer_demographics cd_ref ON ar.demo_sk = cd_ref.cd_demo_sk
JOIN customer_address ca_ref ON ar.addr_sk = ca_ref.ca_address_sk
JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN customer_address ca_bill ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN customer_address ca_ship ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
WHERE ws.ws_ext_list_price > 1000
  AND ws.ws_ship_customer_sk IN (
        SELECT DISTINCT ws2.ws_ship_customer_sk
        FROM web_sales ws2
        WHERE ws2.ws_ext_list_price > 5000
    )
  AND EXISTS (
        SELECT 1
        FROM catalog_returns cr3
        WHERE cr3.cr_item_sk = i.i_item_sk
          AND cr3.cr_fee > 10
    )
ORDER BY profit_rank, i.i_item_id
LIMIT 100
