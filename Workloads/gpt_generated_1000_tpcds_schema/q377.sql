WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_ext_sales
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
    GROUP BY ws_item_sk, ws_bill_customer_sk
),
cr_agg AS (
    SELECT
        cr_item_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    GROUP BY cr_item_sk
)
-- First branch filtered to customers in CA
SELECT
    COALESCE(i.i_item_id, 'UNKNOWN') AS item_id,
    COALESCE(i.i_product_name, 'UNKNOWN') AS product_name,
    ws_agg.total_ext_sales,
    cr_agg.total_return_amount,
    cr_agg.return_cnt,
    lt.avg_price
FROM ws_agg
FULL OUTER JOIN item i
    ON ws_agg.ws_item_sk = i.i_item_sk
LEFT JOIN cr_agg
    ON i.i_item_sk = cr_agg.cr_item_sk
LEFT JOIN customer c_bill
    ON ws_agg.ws_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer_address ca_bill
    ON c_bill.c_current_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_demographics cd_bill
    ON c_bill.c_current_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN household_demographics hd_bill
    ON c_bill.c_current_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
CROSS JOIN LATERAL (
    SELECT AVG(i_current_price) AS avg_price
    FROM item i2
    WHERE i2.i_item_sk = COALESCE(ws_agg.ws_item_sk, i.i_item_sk)
) lt
WHERE ca_bill.ca_country = 'United States'
  AND ca_bill.ca_state = 'CA'
GROUP BY
    COALESCE(i.i_item_id, 'UNKNOWN'),
    COALESCE(i.i_product_name, 'UNKNOWN'),
    ws_agg.total_ext_sales,
    cr_agg.total_return_amount,
    cr_agg.return_cnt,
    lt.avg_price

UNION

-- Second branch filtered to customers in NY
SELECT
    COALESCE(i.i_item_id, 'UNKNOWN') AS item_id,
    COALESCE(i.i_product_name, 'UNKNOWN') AS product_name,
    ws_agg.total_ext_sales,
    cr_agg.total_return_amount,
    cr_agg.return_cnt,
    lt.avg_price
FROM ws_agg
FULL OUTER JOIN item i
    ON ws_agg.ws_item_sk = i.i_item_sk
LEFT JOIN cr_agg
    ON i.i_item_sk = cr_agg.cr_item_sk
LEFT JOIN customer c_bill
    ON ws_agg.ws_bill_customer_sk = c_bill.c_customer_sk
LEFT JOIN customer_address ca_bill
    ON c_bill.c_current_addr_sk = ca_bill.ca_address_sk
LEFT JOIN customer_demographics cd_bill
    ON c_bill.c_current_cdemo_sk = cd_bill.cd_demo_sk
LEFT JOIN household_demographics hd_bill
    ON c_bill.c_current_hdemo_sk = hd_bill.hd_demo_sk
LEFT JOIN catalog_returns cr
    ON i.i_item_sk = cr.cr_item_sk
LEFT JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
LEFT JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
CROSS JOIN LATERAL (
    SELECT AVG(i_current_price) AS avg_price
    FROM item i2
    WHERE i2.i_item_sk = COALESCE(ws_agg.ws_item_sk, i.i_item_sk)
) lt
WHERE ca_bill.ca_country = 'United States'
  AND ca_bill.ca_state = 'NY'
GROUP BY
    COALESCE(i.i_item_id, 'UNKNOWN'),
    COALESCE(i.i_product_name, 'UNKNOWN'),
    ws_agg.total_ext_sales,
    cr_agg.total_return_amount,
    cr_agg.return_cnt,
    lt.avg_price

ORDER BY total_ext_sales DESC
LIMIT 100
