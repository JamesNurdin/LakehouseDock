SELECT
    cp.cp_catalog_page_id,
    cp.cp_type,
    cs.cs_order_number,
    cs.cs_net_paid,
    sold_date.d_date AS sold_date,
    ship_date.d_date AS ship_date,
    inv.inv_quantity_on_hand,
    st.s_store_name,
    st.s_city,
    st.s_state,
    start_date.d_date AS page_start_date,
    end_date.d_date AS page_end_date
FROM catalog_page cp
JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim sold_date
    ON cs.cs_sold_date_sk = sold_date.d_date_sk
JOIN date_dim ship_date
    ON cs.cs_ship_date_sk = ship_date.d_date_sk
JOIN date_dim start_date
    ON cp.cp_start_date_sk = start_date.d_date_sk
JOIN date_dim end_date
    ON cp.cp_end_date_sk = end_date.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = sold_date.d_date_sk
JOIN store st
    ON st.s_closed_date_sk = end_date.d_date_sk
ORDER BY cs.cs_net_paid DESC
LIMIT 100
