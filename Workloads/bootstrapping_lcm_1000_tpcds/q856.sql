SELECT
    cs.cs_order_number,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    sd.d_date AS sold_date,
    shd.d_date AS ship_date,
    ca_bill.ca_state AS billing_state,
    ca_ship.ca_state AS shipping_state,
    s.s_store_id,
    s.s_city,
    s.s_state,
    wp.wp_type,
    wp.wp_url,
    wp.wp_char_count,
    SUM(cs.cs_ext_tax) OVER (
        PARTITION BY s.s_store_id
        ORDER BY cs.cs_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_tax,
    ROW_NUMBER() OVER (ORDER BY cs.cs_net_paid DESC) AS rank_by_net_paid
FROM catalog_sales cs
JOIN date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
JOIN date_dim shd ON cs.cs_ship_date_sk = shd.d_date_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN store s ON s.s_closed_date_sk = sd.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = sd.d_date_sk
WHERE cs.cs_net_paid > 0
ORDER BY cs.cs_net_paid DESC
LIMIT 100
