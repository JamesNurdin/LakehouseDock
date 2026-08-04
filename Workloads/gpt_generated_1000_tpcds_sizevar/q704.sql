WITH
    inv AS (
        SELECT
            inv.inv_item_sk,
            inv.inv_warehouse_sk,
            inv.inv_quantity_on_hand,
            d_inv.d_year AS inv_year,
            i_inv.i_category AS inv_category,
            w_inv.w_warehouse_name AS inv_warehouse_name
        FROM inventory inv
        JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
        JOIN item i_inv ON inv.inv_item_sk = i_inv.i_item_sk
        JOIN warehouse w_inv ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
    ),
    sr AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_return_quantity,
            d_ret.d_year AS ret_year,
            i_ret.i_category AS ret_category,
            st.s_store_name,
            ca_ret.ca_state AS ret_state,
            hd_ret.hd_income_band_sk
        FROM store_returns sr
        JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
        JOIN item i_ret ON sr.sr_item_sk = i_ret.i_item_sk
        JOIN store st ON sr.sr_store_sk = st.s_store_sk
        JOIN customer_address ca_ret ON sr.sr_addr_sk = ca_ret.ca_address_sk
        JOIN household_demographics hd_ret ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
    )
SELECT
    cs.cs_item_sk,
    i.i_category,
    d_sold.d_year AS sold_year,
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type AS ship_type,
    w.w_warehouse_name,
    ca.ca_state AS bill_state,
    hd.hd_income_band_sk,
    ib.ib_upper_bound AS income_upper,
    SUM(cs.cs_ext_sales_price) AS sum_sales_price,
    item_sales.total_sales_for_item,
    CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END AS qty_bucket,
    inv.inv_quantity_on_hand,
    sr.sr_return_quantity,
    wp.wp_url,
    ws.web_name
FROM catalog_sales cs
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
FULL OUTER JOIN inv ON cs.cs_item_sk = inv.inv_item_sk AND cs.cs_warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN sr ON cs.cs_item_sk = sr.sr_item_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d_sold.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(cs2.cs_ext_sales_price) AS total_sales_for_item
    FROM catalog_sales cs2
    WHERE cs2.cs_item_sk = cs.cs_item_sk
) AS item_sales
WHERE cs.cs_ext_sales_price > (
        SELECT MAX(cs3.cs_ext_sales_price)
        FROM catalog_sales cs3
        WHERE cs3.cs_sold_date_sk = (
            SELECT MIN(d4.d_date_sk)
            FROM date_dim d4
            WHERE d4.d_year = 1998
        )
    )
  AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cs.cs_promo_sk
          AND p2.p_discount_active = 'Y'
    )
GROUP BY
    cs.cs_item_sk,
    i.i_category,
    d_sold.d_year,
    cp.cp_department,
    p.p_promo_name,
    sm.sm_type,
    w.w_warehouse_name,
    ca.ca_state,
    hd.hd_income_band_sk,
    ib.ib_upper_bound,
    item_sales.total_sales_for_item,
    CASE WHEN cs.cs_quantity > 10 THEN 'Large' ELSE 'Small' END,
    inv.inv_quantity_on_hand,
    sr.sr_return_quantity,
    wp.wp_url,
    ws.web_name
ORDER BY sum_sales_price DESC
LIMIT 100
