WITH sales_agg AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_order_number,
        SUM(cs.cs_net_paid)      AS total_net_paid,
        COUNT(*)                 AS sales_cnt,
        AVG(cs.cs_sales_price)   AS avg_sales_price,
        MAX(cs.cs_net_profit)    AS max_net_profit,
        CASE WHEN SUM(cs.cs_quantity) > 100 THEN 'HighVolume' ELSE 'LowVolume' END AS volume_category
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 1                                   -- filter 1
      AND cs.cs_sales_price > 10                               -- filter 2
      AND cs.cs_net_paid > 0                                   -- filter 3
      AND cs.cs_sold_date_sk IN (
            SELECT d_date_sk
            FROM date_dim
            WHERE d_year = 2001 AND d_month_seq = 12        -- filter 4 (year & month)
        )
      AND cs.cs_call_center_sk IS NOT NULL                     -- filter 5
    GROUP BY
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_order_number
)
SELECT
    d.d_date,
    t.t_hour,
    i.i_item_id,
    i.i_product_name,
    cc.cc_name                     AS call_center_name,
    cp.cp_department               AS catalog_department,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sa.total_net_paid,
    sa.sales_cnt,
    sa.avg_sales_price,
    sa.max_net_profit,
    sa.volume_category,
    (
        SELECT SUM(cr.cr_return_amount)
        FROM catalog_returns cr
        WHERE cr.cr_order_number = sa.cs_order_number
    )                              AS total_return_amount,
    CASE
        WHEN sa.total_net_paid > (
            SELECT MAX(cs_inner.cs_net_paid)
            FROM catalog_sales cs_inner
        ) THEN 'AboveMax'
        ELSE 'BelowMax'
    END                           AS net_paid_indicator
FROM sales_agg sa
JOIN date_dim d               ON sa.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t               ON sa.cs_sold_time_sk = t.t_time_sk
JOIN item i                   ON sa.cs_item_sk = i.i_item_sk
JOIN call_center cc           ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp          ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib           ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr    ON sr.sr_item_sk = i.i_item_sk AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN web_sales ws        ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM catalog_returns cr2
    WHERE cr2.cr_order_number = sa.cs_order_number
)
ORDER BY sa.total_net_paid DESC
LIMIT 100
