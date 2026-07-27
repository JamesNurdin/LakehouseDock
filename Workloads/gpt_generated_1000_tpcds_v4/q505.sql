WITH filtered_returns AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_refunded_addr_sk,
        cr.cr_item_sk,
        cr.cr_net_loss,
        i.i_category,
        i.i_product_name
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE regexp_like(i.i_product_name, 'Premium')
      AND ca.ca_city LIKE 'A%'
),
agg AS (
    SELECT
        w.w_warehouse_name,
        ca.ca_city,
        fr.i_category,
        SUM(fr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt,
        REGEXP_EXTRACT(fr.i_product_name, '(\\d+)', 1) AS product_number_code
    FROM filtered_returns fr
    JOIN warehouse w ON fr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer_address ca ON fr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY w.w_warehouse_name, ca.ca_city, fr.i_category, REGEXP_EXTRACT(fr.i_product_name, '(\\d+)', 1)
)
SELECT
    w_warehouse_name || ' - ' || ca_city AS warehouse_location,
    i_category,
    total_net_loss,
    returns_cnt,
    product_number_code,
    RANK() OVER (ORDER BY total_net_loss DESC) AS loss_rank
FROM agg
ORDER BY total_net_loss DESC
LIMIT 100
