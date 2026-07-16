WITH returns_summary AS (
    SELECT
        cr.cr_returned_date_sk,
        d.d_year,
        d.d_quarter_name,
        ca_refund.ca_country AS refund_country,
        ca_return.ca_city AS returning_city,
        s.s_store_id AS s_store_id,
        s.s_state AS s_state,
        inv.inv_item_sk AS inv_item_sk,
        inv.inv_quantity_on_hand AS inv_quantity_on_hand,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
        SUM(cr.cr_return_amount) AS total_return_amount,
        AVG(cr.cr_fee) AS avg_fee,
        SUM(cr.cr_return_tax) AS total_return_tax
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca_refund
        ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_address ca_return
        ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2005
      AND s.s_state = 'CA'
    GROUP BY
        cr.cr_returned_date_sk,
        d.d_year,
        d.d_quarter_name,
        ca_refund.ca_country,
        ca_return.ca_city,
        s.s_store_id,
        s.s_state,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand
    HAVING SUM(cr.cr_return_amount) > 500
)
SELECT
    cr_returned_date_sk,
    d_year,
    d_quarter_name,
    refund_country,
    returning_city,
    s_store_id,
    s_state,
    inv_item_sk,
    inv_quantity_on_hand,
    distinct_orders,
    total_return_amount,
    avg_fee,
    total_return_tax,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS rank_by_year
FROM returns_summary
ORDER BY total_return_amount DESC
LIMIT 100
