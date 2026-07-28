WITH catalog_data AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        cs.cs_net_paid AS net_amount,
        cs.cs_quantity,
        'catalog' AS sales_channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_quantity > 5
      AND cs.cs_promo_sk IN (
          SELECT p.p_promo_sk
          FROM tpcds.promotion p
          WHERE p.p_discount_active = 'Y'
      )
),
web_data AS (
    SELECT
        c.c_customer_id,
        i.i_item_id,
        ws.ws_net_paid AS net_amount,
        ws.ws_quantity,
        'web' AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_quantity > 5
      AND ws.ws_promo_sk IN (
          SELECT p.p_promo_sk
          FROM tpcds.promotion p
          WHERE p.p_discount_active = 'Y'
      )
)
SELECT * FROM catalog_data
UNION ALL
SELECT * FROM web_data
ORDER BY net_amount DESC
LIMIT 100
