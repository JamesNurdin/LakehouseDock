WITH
    inventory_agg AS (
        SELECT inv_item_sk,
               inv_warehouse_sk,
               SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_item_sk, inv_warehouse_sk
    ),
    returns_items AS (
        SELECT DISTINCT wr_item_sk AS item_sk
        FROM web_returns
        WHERE wr_return_amt > 500
    ),
    promo_items AS (
        SELECT DISTINCT p_item_sk AS item_sk
        FROM promotion
        WHERE p_discount_active = 'Y'
    ),
    item_without_promo AS (
        SELECT item_sk
        FROM returns_items
        EXCEPT
        SELECT item_sk FROM promo_items
    ),
    ranked_items AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_product_name,
               ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY i.i_current_price DESC) AS price_rank
        FROM item i
        JOIN item_without_promo ip ON i.i_item_sk = ip.item_sk
    )
SELECT
    cc.cc_call_center_id,
    d.d_date,
    c.c_customer_id,
    ca.ca_city,
    hd.hd_income_band_sk,
    i.i_item_id,
    i.i_product_name,
    inv_agg.total_qty,
    p.p_promo_name,
    wr.wr_return_amt,
    ri.price_rank,
    ROW_NUMBER() OVER (ORDER BY inv_agg.total_qty DESC) AS global_rank
FROM inventory_agg inv_agg
JOIN item i ON inv_agg.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
JOIN date_dim d ON d.d_date_sk = wr.wr_returned_date_sk
FULL OUTER JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
JOIN customer c ON c.c_customer_sk = wr.wr_refunded_customer_sk
JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN ranked_items ri ON ri.i_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND ca.ca_state = 'CA'
  AND w.w_city = 'Los Angeles'
  AND i.i_current_price > 10
  AND p.p_discount_active = 'Y'
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
          AND p2.p_start_date_sk = d.d_date_sk
          AND p2.p_discount_active = 'Y'
    )
ORDER BY inv_agg.total_qty DESC
LIMIT 100
