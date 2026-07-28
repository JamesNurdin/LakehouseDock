WITH filtered_items AS (
        SELECT i_item_sk,
               i_item_id,
               i_category,
               i_current_price,
               i_brand,
               i_color
        FROM item
        WHERE i_current_price BETWEEN 50 AND 200
          AND i_brand IN ('BrandA', 'BrandB')
          AND i_color = 'Blue'
    ),
    web_data AS (
        SELECT ws.ws_order_number,
               ws.ws_sold_date_sk,
               ws.ws_net_profit,
               ws.ws_quantity,
               i.i_category,
               i.i_item_id,
               cd.cd_gender,
               cd.cd_education_status,
               hd.hd_buy_potential,
               ib.ib_lower_bound,
               sm.sm_ship_mode_id,
               p.p_discount_active,
               p.p_channel_press,
               ws.ws_item_sk
        FROM web_sales ws
        JOIN filtered_items i        ON ws.ws_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib          ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN ship_mode sm           ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN promotion p            ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site wsite         ON ws.ws_web_site_sk = wsite.web_site_sk
        WHERE cd.cd_gender = 'M'
          AND cd.cd_education_status = 'College'
          AND hd.hd_buy_potential = '>10000'
          AND ib.ib_lower_bound >= 50000
          AND p.p_channel_press = 'N'
          AND sm.sm_contract LIKE 'A%'
    )
SELECT wd.ws_order_number,
       wd.ws_sold_date_sk,
       wd.i_item_id,
       wd.i_category,
       wd.ws_net_profit,
       wd.ws_quantity,
       wd.cd_gender,
       wd.hd_buy_potential,
       wd.sm_ship_mode_id,
       wd.p_discount_active,
       RANK() OVER (PARTITION BY wd.i_category ORDER BY wd.ws_net_profit DESC) AS profit_rank,
       ROW_NUMBER() OVER (PARTITION BY wd.i_category ORDER BY wd.ws_sold_date_sk) AS seq_by_date
FROM web_data wd
WHERE EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_item_sk = wd.ws_item_sk
          AND sr.sr_return_quantity > 0
          AND sr.sr_return_amt > 0
    )
ORDER BY profit_rank,
         wd.ws_net_profit DESC
LIMIT 100
