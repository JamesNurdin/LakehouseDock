WITH returns_enriched AS (
    SELECT
        cr.cr_returning_customer_sk,
        i.i_item_id,
        i.i_category,
        i.i_current_price,
        ca_returning.ca_state,
        ca_returning.ca_gmt_offset,
        hd_returning.hd_income_band_sk,
        inv.inv_quantity_on_hand,
        cr.cr_return_amount,
        CASE
            WHEN i.i_current_price < 5 THEN 'Low'
            WHEN i.i_current_price < 10 THEN 'Mid'
            ELSE 'High'
        END AS price_category,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY cr.cr_return_amount DESC) AS rn_category,
        RANK() OVER (ORDER BY cr.cr_return_amount DESC) AS overall_rank,
        (SELECT AVG(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_item_sk = i.i_item_sk) AS avg_return_amount_for_item
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    WHERE i.i_units IN ('Carton', 'Case')
      AND i.i_current_price BETWEEN 1 AND 10
      AND ca_returning.ca_state = 'CA'
      AND ca_returning.ca_gmt_offset = -6.00
      AND hd_returning.hd_income_band_sk = 5
      AND inv.inv_quantity_on_hand > 0
)
SELECT *
FROM returns_enriched
ORDER BY cr_return_amount DESC
LIMIT 100
