WITH sales_agg AS (
    SELECT
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_carrier,
        i.i_category,
        i.i_brand,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        SUM(CASE WHEN cr.cr_store_credit > 0 THEN cr.cr_store_credit ELSE 0 END) AS total_store_credit
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
    WHERE sm.sm_carrier IN ('AIRBORNE', 'MSC')
      AND ib.ib_upper_bound > 50000
      AND i.i_current_price BETWEEN 20 AND 2000
      AND cs.cs_order_number NOT IN (
          SELECT cr2.cr_order_number
          FROM catalog_returns cr2
          WHERE cr2.cr_store_credit > 500
      )
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_item_sk = cs.cs_item_sk
            AND sr.sr_return_quantity > 2
      )
    GROUP BY
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_carrier,
        i.i_category,
        i.i_brand
)
SELECT
    hd_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    sm_carrier,
    i_category,
    i_brand,
    total_sales,
    avg_profit,
    order_cnt,
    total_store_credit,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM sales_agg
ORDER BY total_sales DESC
LIMIT 100
