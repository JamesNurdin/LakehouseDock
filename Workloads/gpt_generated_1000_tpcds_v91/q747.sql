/* Goal: Identify item SKUs that were returned both in physical stores and via the web in the year 2002 by customers residing in California, and only when the item was under an active promotion at the time of the return. */
WITH store_items AS (
    SELECT DISTINCT sr.sr_item_sk AS item_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND ca.ca_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = sr.sr_item_sk
            AND p.p_discount_active = 'Y'
            AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      )
),
web_items AS (
    SELECT DISTINCT wr.wr_item_sk AS item_sk
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2002
      AND ca.ca_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = wr.wr_item_sk
            AND p.p_discount_active = 'Y'
            AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
      )
)
SELECT item_sk
FROM (
    SELECT item_sk FROM store_items
    INTERSECT
    SELECT item_sk FROM web_items
) AS intersected_items
ORDER BY item_sk
LIMIT 100
