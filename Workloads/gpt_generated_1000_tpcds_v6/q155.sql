WITH joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        i.i_current_price,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_location_type,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_channel_press,
        cr.cr_return_amount,
        cr.cr_net_loss
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY')
      AND ca.ca_zip LIKE '9%'
      AND ca.ca_location_type = 'single family'
      AND hd.hd_dep_count BETWEEN 1 AND 5
      AND hd.hd_income_band_sk IN (5, 6, 10)
      AND p.p_channel_dmail = 'Y'
)
SELECT
    jd.i_brand,
    jd.ca_state,
    SUM(jd.sr_return_amt) AS total_store_return_amount,
    SUM(jd.cr_return_amount) AS total_catalog_return_amount,
    SUM(jd.sr_net_loss) + SUM(jd.cr_net_loss) AS total_net_loss,
    COUNT(*) AS transaction_count,
    ROW_NUMBER() OVER (PARTITION BY jd.i_brand ORDER BY SUM(jd.sr_return_amt) DESC) AS brand_state_rank,
    (
        SELECT AVG(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = jd.i_item_sk
    ) AS avg_item_catalog_return_amount
FROM joined_data jd
GROUP BY jd.i_brand, jd.ca_state, jd.i_item_sk
HAVING SUM(jd.sr_return_amt) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
