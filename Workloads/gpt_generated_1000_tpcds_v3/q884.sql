WITH filtered_items AS (
    SELECT
        i_item_sk,
        i_item_desc,
        regexp_extract(i_item_desc, '(\\d+)', 1) AS numeric_code
    FROM item
    WHERE regexp_like(i_item_desc, '\\d')
)

SELECT
    sales_i_item_sk,
    sales_i_item_desc,
    'sales' AS record_type,
    total_amount,
    profit_flag,
    city_state,
    item_desc_prefix
FROM (
    SELECT
        fi.i_item_sk AS sales_i_item_sk,
        fi.i_item_desc AS sales_i_item_desc,
        SUM(cs.cs_net_paid) AS total_amount,
        CASE WHEN SUM(cs.cs_net_paid) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        SUBSTRING(fi.i_item_desc, 1, 5) AS item_desc_prefix
    FROM catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
      AND ca.ca_street_name LIKE '%Hill%'
    GROUP BY fi.i_item_sk, fi.i_item_desc, ca.ca_city, ca.ca_state
) AS sales

UNION ALL

SELECT
    returns_i_item_sk,
    returns_i_item_desc,
    'returns' AS record_type,
    total_amount,
    profit_flag,
    city_state,
    item_desc_prefix
FROM (
    SELECT
        fi.i_item_sk AS returns_i_item_sk,
        fi.i_item_desc AS returns_i_item_desc,
        SUM(sr.sr_return_amt) AS total_amount,
        CASE WHEN SUM(sr.sr_return_amt) > 0 THEN 'Loss' ELSE 'Profit' END AS profit_flag,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS city_state,
        SUBSTRING(fi.i_item_desc, 1, 5) AS item_desc_prefix
    FROM store_returns sr
    JOIN filtered_items fi ON sr.sr_item_sk = fi.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '1999-01-01' AND DATE '1999-12-31'
      AND ca.ca_street_name LIKE '%Hill%'
    GROUP BY fi.i_item_sk, fi.i_item_desc, ca.ca_city, ca.ca_state
) AS returns

LIMIT 100
