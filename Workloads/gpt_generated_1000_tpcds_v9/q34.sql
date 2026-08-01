/* Goal: Identify top billing/shipping customer‑item combinations where the billing customer has both purchased sports items and experienced a return, classify purchase potential, and summarize sales, quantity, profit and return counts. */
WITH cs_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit
    FROM tpcds.catalog_sales cs
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_ship_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_ship_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_ship_addr_sk,
        cs.cs_item_sk,
        cs.cs_catalog_page_sk
)
SELECT
    cust_bill.c_customer_id AS billing_customer_id,
    cust_ship.c_customer_id AS shipping_customer_id,
    i.i_item_id,
    i.i_product_name,
    cp.cp_description,
    SUM(cs_agg.total_quantity) AS sum_quantity,
    SUM(cs_agg.total_sales) AS sum_sales,
    SUM(cs_agg.total_profit) AS sum_profit,
    CASE
        WHEN hd_bill.hd_buy_potential = '1001-5000' THEN 'Mid'
        WHEN hd_bill.hd_buy_potential = '>10000' THEN 'High'
        ELSE 'Low'
    END AS purchase_potential_category,
    COUNT(DISTINCT wr.wr_order_number) AS return_transactions
FROM cs_agg
JOIN tpcds.customer cust_bill
    ON cs_agg.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN tpcds.customer cust_ship
    ON cs_agg.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN tpcds.customer_address addr_bill
    ON cs_agg.cs_bill_addr_sk = addr_bill.ca_address_sk
JOIN tpcds.customer_address addr_ship
    ON cs_agg.cs_ship_addr_sk = addr_ship.ca_address_sk
JOIN tpcds.customer_demographics cd_bill
    ON cs_agg.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.customer_demographics cd_ship
    ON cs_agg.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN tpcds.household_demographics hd_bill
    ON cs_agg.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN tpcds.household_demographics hd_ship
    ON cs_agg.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN tpcds.catalog_page cp
    ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.item i
    ON cs_agg.cs_item_sk = i.i_item_sk
LEFT JOIN tpcds.web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
    AND wr.wr_returned_date_sk = cs_agg.cs_sold_date_sk
WHERE cust_bill.c_customer_sk IN (
    SELECT cs1.cs_bill_customer_sk
    FROM tpcds.catalog_sales cs1
    WHERE cs1.cs_item_sk IN (
        SELECT i1.i_item_sk
        FROM tpcds.item i1
        WHERE i1.i_category = 'Sports'
    )
    INTERSECT
    SELECT wr1.wr_refunded_customer_sk
    FROM tpcds.web_returns wr1
    WHERE wr1.wr_return_amt > 0
)
GROUP BY
    cust_bill.c_customer_id,
    cust_ship.c_customer_id,
    i.i_item_id,
    i.i_product_name,
    cp.cp_description,
    hd_bill.hd_buy_potential
ORDER BY
    sum_sales DESC,
    cust_bill.c_customer_id
LIMIT 100
