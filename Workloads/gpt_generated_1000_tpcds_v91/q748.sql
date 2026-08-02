SELECT
    w.w_warehouse_name,
    w.w_zip,
    cp.cp_department,
    sm.sm_type,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    AVG(cs.cs_net_profit) AS avg_profit,
    COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
    CASE
        WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    (
        SELECT SUM(sr.sr_return_amt)
        FROM store_returns sr
        WHERE sr.sr_addr_sk = ca.ca_address_sk
    ) AS total_store_return_amount
FROM
    catalog_sales cs
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN web_returns wr
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
WHERE
    cp.cp_department = 'Electronics'
    AND cs.cs_quantity > 5
    AND cs.cs_net_paid > 200.0
    AND w.w_zip = '63451'
    AND wr.wr_reversed_charge < 100.0
    AND wr.wr_account_credit > 0.5
    AND EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_addr_sk = ca.ca_address_sk
          AND sr.sr_return_amt > 50.0
    )
GROUP BY
    w.w_warehouse_name,
    w.w_zip,
    cp.cp_department,
    sm.sm_type,
    ca.ca_address_sk
ORDER BY
    total_sales DESC
LIMIT 100
