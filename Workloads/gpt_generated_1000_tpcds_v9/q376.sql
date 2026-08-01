WITH inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
returned_amounts AS (
    SELECT cr.cr_item_sk AS item_sk,
           SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
    UNION ALL
    SELECT wr.wr_item_sk AS item_sk,
           SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
combined_returns AS (
    SELECT item_sk,
           SUM(total_return_amount) AS total_return_amount
    FROM returned_amounts
    GROUP BY item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    cp.cp_catalog_page_number,
    sm.sm_type AS ship_mode_type,
    ca_sold.ca_country,
    ca_sold.ca_state,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.cs_net_profit) AS avg_item_net_profit,
    SUM(sr.sr_return_quantity) AS total_store_return_qty,
    SUM(wr.wr_return_quantity) AS total_web_return_qty,
    inv_agg.total_on_hand,
    cr_comb.total_return_amount AS total_return_amount_all_channels
FROM
    catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_sold ON cs.cs_bill_addr_sk = ca_sold.ca_address_sk
    JOIN customer_demographics cd_sold ON cs.cs_bill_cdemo_sk = cd_sold.cd_demo_sk
    JOIN household_demographics hd_sold ON cs.cs_bill_hdemo_sk = hd_sold.hd_demo_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_store ON sr.sr_addr_sk = ca_store.ca_address_sk
    LEFT JOIN customer_demographics cd_store ON sr.sr_cdemo_sk = cd_store.cd_demo_sk
    LEFT JOIN household_demographics hd_store ON sr.sr_hdemo_sk = hd_store.hd_demo_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_webrefund ON wr.wr_refunded_addr_sk = ca_webrefund.ca_address_sk
    LEFT JOIN customer_demographics cd_webrefund ON wr.wr_refunded_cdemo_sk = cd_webrefund.cd_demo_sk
    LEFT JOIN household_demographics hd_webrefund ON wr.wr_refunded_hdemo_sk = hd_webrefund.hd_demo_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    LEFT JOIN customer_address ca_return_refund ON cr.cr_refunded_addr_sk = ca_return_refund.ca_address_sk
    LEFT JOIN customer_demographics cd_return_refund ON cr.cr_refunded_cdemo_sk = cd_return_refund.cd_demo_sk
    LEFT JOIN household_demographics hd_return_refund ON cr.cr_refunded_hdemo_sk = hd_return_refund.hd_demo_sk
    LEFT JOIN ship_mode sm_return ON cr.cr_ship_mode_sk = sm_return.sm_ship_mode_sk
    LEFT JOIN catalog_page cp_return ON cr.cr_catalog_page_sk = cp_return.cp_catalog_page_sk
    LEFT JOIN inventory_agg inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    LEFT JOIN combined_returns cr_comb ON i.i_item_sk = cr_comb.item_sk
WHERE
    ca_sold.ca_country = 'United States'
    AND cp.cp_department = 'Sports'
    AND sm.sm_type = 'AIR'
    AND i.i_brand = 'Brand#1'
    AND cs.cs_net_paid > 500.00
    AND (inv_agg.total_on_hand IS NULL OR inv_agg.total_on_hand > 0)
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_amount > 100.00
    )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    cp.cp_department,
    cp.cp_catalog_page_number,
    sm.sm_type,
    ca_sold.ca_country,
    ca_sold.ca_state,
    inv_agg.total_on_hand,
    cr_comb.total_return_amount
HAVING
    SUM(cs.cs_net_profit) > 1000.00
ORDER BY
    total_net_paid DESC
LIMIT 100
