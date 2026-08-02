/*
Goal: Aggregate return and sales metrics by catalog page type and item brand, broken down by the gender of the refunded customer.
*/
SELECT
    cp.cp_type,
    i_item.i_brand,
    CASE
        WHEN cd_refunded.cd_gender = 'F' THEN 'Female_Refunded'
        WHEN cd_refunded.cd_gender = 'M' THEN 'Male_Refunded'
        ELSE 'Other_Refunded'
    END AS refunded_gender_group,
    SUM(cr.cr_return_amount) AS total_return_amount,
    SUM(ws.ws_net_paid) AS total_sales_net_paid,
    COUNT(DISTINCT cd_refunded.cd_demo_sk) AS distinct_refunded_customers,
    COUNT(DISTINCT cd_bill.cd_demo_sk) AS distinct_bill_customers,
    COUNT(DISTINCT i_item.i_item_id) AS distinct_items_sold,
    SUM(DISTINCT cr.cr_return_amount) AS distinct_sum_return_amount
FROM tpcds.catalog_returns cr
JOIN tpcds.item i_item
    ON cr.cr_item_sk = i_item.i_item_sk
JOIN tpcds.catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN tpcds.customer_demographics cd_returning
    ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN tpcds.inventory inv_ret
    ON inv_ret.inv_item_sk = i_item.i_item_sk
JOIN tpcds.web_sales ws
    ON ws.ws_item_sk = i_item.i_item_sk
JOIN tpcds.customer_demographics cd_bill
    ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ship
    ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.inventory inv_ws
    ON inv_ws.inv_item_sk = i_item.i_item_sk
WHERE cp.cp_type IN ('monthly', 'quarterly')
GROUP BY
    cp.cp_type,
    i_item.i_brand,
    CASE
        WHEN cd_refunded.cd_gender = 'F' THEN 'Female_Refunded'
        WHEN cd_refunded.cd_gender = 'M' THEN 'Male_Refunded'
        ELSE 'Other_Refunded'
    END
HAVING
    SUM(cr.cr_return_amount) > 1000
    AND COUNT(DISTINCT cd_refunded.cd_demo_sk) >= 3
ORDER BY
    SUM(cr.cr_return_amount) DESC
LIMIT 100
