WITH returns_detail AS (
    SELECT
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        cr.cr_fee,
        cr.cr_returned_date_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        w.w_country,
        w.w_city,
        sm.sm_type,
        inv.inv_quantity_on_hand,
        hd_ret.hd_income_band_sk AS ret_income_band,
        hd_ref.hd_income_band_sk AS ref_income_band,
        ca_ret.ca_country AS ret_country,
        ca_ref.ca_country AS ref_country
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    WHERE cr.cr_fee > 20.00
      AND cr.cr_return_amount > 500.00
      AND w.w_country = 'United States'
)
SELECT
    w_country,
    w_city,
    sm_type,
    i_category,
    i_brand,
    COUNT(DISTINCT cr_item_sk) AS distinct_items_returned,
    SUM(cr_return_quantity) AS total_return_quantity,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    AVG(ret_income_band) AS avg_returning_income_band,
    AVG(ref_income_band) AS avg_refunded_income_band,
    COUNT(CASE WHEN ret_country = 'United States' THEN 1 END) AS returning_us_count,
    COUNT(CASE WHEN ref_country = 'Canada' THEN 1 END) AS refunded_canada_count
FROM returns_detail
GROUP BY
    w_country,
    w_city,
    sm_type,
    i_category,
    i_brand
HAVING SUM(cr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 50
