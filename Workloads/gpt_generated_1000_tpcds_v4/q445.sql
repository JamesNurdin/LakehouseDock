/* Goal: Compare total net loss from store returns and catalog returns for a recent date range, highlighting items with high loss and only considering items sold in 'Box' units and items that had active promotions. */
WITH store_return_agg AS (
    SELECT
        'store' AS return_source,
        s.s_store_id AS store_id,
        i.i_item_id AS item_id,
        SUM(sr.sr_net_loss) AS total_net_loss,
        CASE WHEN SUM(sr.sr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM store_returns sr
    JOIN store s
      ON sr.sr_store_sk = s.s_store_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450815 AND 2451046
      AND i.i_units = 'Box'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY s.s_store_id, i.i_item_id
),
catalog_return_agg AS (
    SELECT
        'catalog' AS return_source,
        CAST(NULL AS varchar) AS store_id,
        i.i_item_id AS item_id,
        SUM(cr.cr_net_loss) AS total_net_loss,
        CASE WHEN SUM(cr.cr_net_loss) > 5000 THEN 'High' ELSE 'Low' END AS loss_category
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2451046
      AND i.i_class_id IN (
          SELECT DISTINCT i2.i_class_id
          FROM item i2
          WHERE i2.i_units = 'Box'
      )
    GROUP BY i.i_item_id
)
SELECT *
FROM store_return_agg
UNION ALL
SELECT *
FROM catalog_return_agg
ORDER BY total_net_loss DESC
LIMIT 100
