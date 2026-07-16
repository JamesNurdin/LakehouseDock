WITH aggregated AS (
    SELECT
        date_dim.d_year AS year,
        date_dim.d_month_seq AS month_seq,
        store.s_store_id AS store_id,
        store.s_state AS store_state,
        refunded_addr.ca_state AS refunded_state,
        returning_addr.ca_state AS returning_state,
        COUNT(DISTINCT catalog_returns.cr_order_number) AS total_orders,
        SUM(catalog_returns.cr_net_loss) AS total_net_loss,
        SUM(catalog_returns.cr_return_amount) AS total_return_amount,
        SUM(inventory.inv_quantity_on_hand) AS total_inventory_on_hand,
        AVG(catalog_returns.cr_return_quantity) AS avg_return_quantity,
        MAX(catalog_returns.cr_return_tax) AS max_return_tax
    FROM catalog_returns
    JOIN date_dim
        ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN customer_address AS refunded_addr
        ON catalog_returns.cr_refunded_addr_sk = refunded_addr.ca_address_sk
    JOIN customer_address AS returning_addr
        ON catalog_returns.cr_returning_addr_sk = returning_addr.ca_address_sk
    JOIN inventory
        ON inventory.inv_date_sk = date_dim.d_date_sk
    JOIN store
        ON store.s_closed_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year BETWEEN 2000 AND 2005
      AND store.s_state = 'CA'
    GROUP BY
        date_dim.d_year,
        date_dim.d_month_seq,
        store.s_store_id,
        store.s_state,
        refunded_addr.ca_state,
        returning_addr.ca_state
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_net_loss DESC) AS rank,
    year,
    month_seq,
    store_id,
    store_state,
    refunded_state,
    returning_state,
    total_orders,
    total_net_loss,
    total_return_amount,
    total_inventory_on_hand,
    avg_return_quantity,
    max_return_tax
FROM aggregated
ORDER BY rank
LIMIT 100
