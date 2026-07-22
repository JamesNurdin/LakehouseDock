WITH base_data AS (
    SELECT
        i.i_brand AS i_brand,
        i.i_class AS i_class,
        ca_sales.ca_state AS ca_state,
        cp.cp_department AS cp_department,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_ticket_number AS ss_ticket_number,
        sr.sr_return_amt AS sr_return_amt,
        sr.sr_store_credit AS sr_store_credit,
        cr.cr_return_amount AS cr_return_amount,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand
    FROM
        store_sales ss
        JOIN item i
            ON ss.ss_item_sk = i.i_item_sk
        JOIN customer_address ca_sales
            ON ss.ss_addr_sk = ca_sales.ca_address_sk
        JOIN store_returns sr
            ON sr.sr_item_sk = ss.ss_item_sk
            AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN customer_address ca_return
            ON sr.sr_addr_sk = ca_return.ca_address_sk
        JOIN catalog_returns cr
            ON cr.cr_item_sk = i.i_item_sk
        JOIN customer_address ca_refunded
            ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
        JOIN customer_address ca_returning
            ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN inventory inv
            ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2001-12-31'
        AND ca_sales.ca_state = 'TX'
        AND ca_sales.ca_location_type = 'single family'
        AND i.i_container = 'Unknown'
        AND sr.sr_return_amt > 100
)
SELECT
    i_brand,
    i_class,
    ca_state,
    cp_department,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(sr_return_amt) AS total_store_returns,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(inv_quantity_on_hand) AS total_on_hand,
    AVG(sr_store_credit) AS avg_store_credit,
    COUNT(DISTINCT ss_ticket_number) AS sales_transactions,
    MIN(sr_return_amt) AS min_return_amt,
    MAX(sr_return_amt) AS max_return_amt
FROM
    base_data
GROUP BY
    i_brand,
    i_class,
    ca_state,
    cp_department
HAVING
    SUM(ss_ext_sales_price) > 5000
    AND COUNT(DISTINCT ss_ticket_number) >= 5
ORDER BY
    total_sales DESC
LIMIT 100
