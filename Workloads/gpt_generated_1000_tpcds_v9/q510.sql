WITH sales_demo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_ext_list_price,
        ws.ws_ext_discount_amt,
        ws.ws_coupon_amt,
        ARRAY[ws.ws_ext_list_price, ws.ws_ext_discount_amt, ws.ws_coupon_amt] AS price_components,
        cd.cd_gender,
        cd.cd_education_status,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sr.sr_return_amt,
        sr.sr_net_loss
    FROM web_sales ws
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE cd.cd_gender = 'M'
      AND cd.cd_education_status = 'College'
      AND hd.hd_buy_potential IN ('5001-10000', '>10000')
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_lower_bound >= 40000
      AND ws.ws_ext_sales_price > 5000
      AND sr.sr_return_amt > 0
)
SELECT
    sd.ws_order_number,
    sd.cd_gender,
    sd.cd_education_status,
    sd.hd_buy_potential,
    sd.hd_vehicle_count,
    sd.ib_income_band_sk,
    sd.sr_return_amt,
    sd.sr_net_loss,
    CASE
        WHEN sd.sr_net_loss > 1000 THEN 'High Loss'
        ELSE 'Low/Medium Loss'
    END AS loss_category,
    RANK() OVER (PARTITION BY sd.ib_income_band_sk ORDER BY sd.sr_net_loss DESC) AS loss_rank,
    t.price_component,
    CASE t.comp_idx
        WHEN 1 THEN 'list_price'
        WHEN 2 THEN 'discount_amt'
        WHEN 3 THEN 'coupon_amt'
        ELSE 'unknown'
    END AS component_type
FROM sales_demo sd
CROSS JOIN UNNEST(sd.price_components) WITH ORDINALITY AS t(price_component, comp_idx)
WHERE t.price_component > 0
ORDER BY loss_rank
LIMIT 100
