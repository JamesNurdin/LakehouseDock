WITH detailed_returns AS (
    SELECT
        sr.sr_store_sk,
        s.s_store_name,
        d.d_year,
        i.i_category,
        i.i_brand,
        cr.cr_return_amount,
        sr.sr_net_loss,
        cc.cc_market_manager,
        sm.sm_carrier,
        inv.inv_quantity_on_hand,
        CASE 
            WHEN sr.sr_net_loss > 1000 THEN 'High'
            WHEN sr.sr_net_loss > 500 THEN 'Medium'
            ELSE 'Low'
        END AS loss_category,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND i.i_brand = 'Brand#12'
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk = 5
      AND sr.sr_return_quantity > 1
)
SELECT
    loss_category,
    COUNT(*) AS return_cnt,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(sr_net_loss) AS avg_net_loss,
    SUM(inv_quantity_on_hand) AS total_inventory_on_hand
FROM detailed_returns
GROUP BY loss_category
HAVING SUM(sr_net_loss) > 10000
ORDER BY total_net_loss DESC
LIMIT 100
