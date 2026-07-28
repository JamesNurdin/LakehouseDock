WITH filtered AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        cc.cc_call_center_id,
        cc.cc_mkt_class,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        p.p_promo_name,
        p.p_response_target,
        p.p_channel_event
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cc.cc_mkt_class = 'National'
      AND p.p_response_target > 5
      AND cs.cs_sales_price > 20
      AND hd.hd_income_band_sk IN (1, 2, 3)
      AND cs.cs_quantity >= 2
)
SELECT DISTINCT
    f.cs_order_number,
    f.cs_sold_date_sk,
    f.cs_sales_price,
    f.cs_net_profit,
    f.cc_call_center_id,
    f.cc_mkt_class,
    f.hd_income_band_sk,
    f.p_promo_name,
    RANK() OVER (PARTITION BY f.p_promo_name ORDER BY f.cs_net_profit DESC) AS profit_rank,
    ROW_NUMBER() OVER (ORDER BY f.cs_net_profit DESC) AS overall_row_num
FROM filtered f
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.promotion p_ex
    WHERE p_ex.p_promo_sk = f.cs_promo_sk
      AND p_ex.p_channel_event = 'Y'
)
ORDER BY f.cs_net_profit DESC
LIMIT 100
