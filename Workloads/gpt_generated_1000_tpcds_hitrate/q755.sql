WITH city_words AS (
        SELECT cc.cc_call_center_sk, city_word
        FROM call_center cc
        CROSS JOIN UNNEST(split(cc.cc_city, ' ')) AS t(city_word)
        WHERE cc.cc_city IS NOT NULL
    ),
    joined AS (
        SELECT
            i.i_item_sk,
            i.i_item_id,
            i.i_brand,
            i.i_category,
            i.i_color,
            i.i_current_price,
            cr.cr_return_amount,
            cr.cr_fee,
            cr.cr_net_loss,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            ws.ws_quantity,
            ws.ws_ext_sales_price,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            inv.inv_quantity_on_hand,
            cc.cc_company,
            sm.sm_type,
            r.r_reason_desc,
            hd.hd_buy_potential,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            ca.ca_city,
            c.c_first_name,
            c.c_last_name,
            t.t_shift,
            t.t_second,
            wp.wp_url,
            s.s_store_name,
            cw.city_word
        FROM item i
        LEFT JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
        LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        LEFT JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        LEFT JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
        LEFT JOIN city_words cw ON cc.cc_call_center_sk = cw.cc_call_center_sk
        WHERE i.i_current_price BETWEEN 1000 AND 5000
          AND cc.cc_company IN (2, 3, 4)
          AND sm.sm_type = 'AIR'
          AND t.t_shift = 'first'
          AND ib.ib_lower_bound >= 20000
          AND wp.wp_type = 'article'
    )
SELECT
    i_brand,
    i_category,
    cc_company,
    sm_type,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(ws_ext_sales_price) AS avg_sales_price,
    COUNT(DISTINCT ca_city) AS distinct_cities,
    COUNT(DISTINCT city_word) AS distinct_city_words
FROM joined
WHERE i_item_sk IN (
        SELECT i2.i_item_sk FROM item i2 WHERE i2.i_color = 'Red'
    )
GROUP BY CUBE(i_brand, i_category, cc_company, sm_type)
HAVING SUM(cr_return_amount) > 0
ORDER BY total_return_amount DESC
LIMIT 100
