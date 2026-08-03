WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        d_sold.d_year,
        d_sold.d_date,
        t_sold.t_hour,
        sm.sm_type,
        ca.ca_state,
        inv.inv_quantity_on_hand,
        wp.wp_type
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    LEFT JOIN web_page wp
        ON wp.wp_creation_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2000
      AND sm.sm_type = 'AIR'
      AND t_sold.t_hour BETWEEN 8 AND 12
      AND cr.cr_net_loss > 100
      AND cs.cs_item_sk IN (
            SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0
      )
      AND ca.ca_state IN (
            SELECT ca_state FROM customer_address WHERE ca_country = 'United States'
            INTERSECT
            SELECT ca_state FROM customer_address WHERE ca_gmt_offset > -5
      )
),
agg AS (
    SELECT
        d_year,
        sm_type,
        ca_state,
        SUM(cs_net_paid)      AS total_sales,
        SUM(cr_net_loss)      AS total_loss,
        AVG(inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT cs_order_number) AS orders
    FROM base
    GROUP BY d_year, sm_type, ca_state
)
SELECT
    d_year,
    sm_type,
    ca_state,
    total_sales,
    total_loss,
    avg_inventory,
    orders,
    total_loss / total_sales AS loss_ratio
FROM agg
WHERE total_sales > 1000
ORDER BY loss_ratio DESC
LIMIT 100
