WITH sales_data AS (
    SELECT
        ss.ss_ticket_number AS order_id,
        d.d_year,
        i.i_category,
        ca.ca_country,
        0 AS quantity,
        ss.ss_net_paid AS amount,
        ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY ss.ss_net_profit DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND i.i_category = 'Books'
      AND ca.ca_country = 'United States'
      AND ss.ss_net_paid > 1000
      AND ss.ss_quantity > 0
),
returns_data AS (
    SELECT
        cr.cr_order_number AS order_id,
        d.d_year,
        i.i_category,
        ca.ca_country,
        cr.cr_return_quantity AS quantity,
        cr.cr_return_amount AS amount,
        NULL AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
      AND i.i_category = 'Books'
      AND ca.ca_country = 'United States'
      AND cr.cr_return_quantity > 0
)
SELECT
    sd.order_id,
    sd.d_year,
    sd.i_category,
    sd.ca_country,
    sd.quantity,
    sd.amount,
    sd.rn
FROM sales_data sd
EXCEPT
SELECT
    rd.order_id,
    rd.d_year,
    rd.i_category,
    rd.ca_country,
    rd.quantity,
    rd.amount,
    rd.rn
FROM returns_data rd
ORDER BY rn
LIMIT 100
