/* goal: Identify top‑selling items versus top‑returning items, broken down by income band, shipping mode and return reason, and compare catalog‑sale performance with store‑return performance. */
WITH sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_order_number AS order_number,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt,
        sm.sm_type AS ship_mode_type,
        p.p_promo_name AS promo_name,
        hd.hd_income_band_sk AS income_band_sk,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2450825
      AND cs.cs_quantity > 1
      AND p.p_channel_demo = 'N'
      AND sm.sm_type = 'AIR'
      AND ib.ib_lower_bound >= 50000
      AND ib.ib_upper_bound <= 150000
    GROUP BY cs.cs_item_sk,
             cs.cs_order_number,
             sm.sm_type,
             p.p_promo_name,
             hd.hd_income_band_sk,
             ib.ib_lower_bound,
             ib.ib_upper_bound
),
returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        cr.cr_order_number AS order_number,
        SUM(cr.cr_return_amount) AS total_return_amt,
        AVG(cr.cr_return_quantity) AS avg_return_qty,
        COUNT(*) AS return_cnt,
        r.r_reason_desc AS reason_desc,
        sm.sm_type AS ship_mode_type,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        hd.hd_income_band_sk AS income_band_sk,
        ib.ib_lower_bound AS ib_lower_bound,
        ib.ib_upper_bound AS ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_item_sk ORDER BY SUM(cr.cr_return_amount) DESC) AS return_rank
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450830 AND 2450840
      AND cr.cr_return_quantity > 0
      AND r.r_reason_id = 'AAAAAAAACBAAAAAA'
      AND sm.sm_code = '01'
      AND ib.ib_upper_bound <= 200000
      AND ib.ib_lower_bound >= 0
    GROUP BY cr.cr_item_sk,
             cr.cr_order_number,
             r.r_reason_desc,
             sm.sm_type,
             hd.hd_income_band_sk,
             ib.ib_lower_bound,
             ib.ib_upper_bound
)
SELECT
    combined.item_sk,
    combined.order_number,
    combined.metric_type,
    combined.metric_value,
    combined.metric_rank,
    CONCAT(CAST(combined.ib_lower_bound AS VARCHAR), '-', CAST(combined.ib_upper_bound AS VARCHAR)) AS income_band_range,
    combined.ship_mode_type,
    combined.reason_desc,
    combined.store_return_amt
FROM (
    SELECT
        sa.item_sk,
        sa.order_number,
        'sales' AS metric_type,
        sa.total_sales AS metric_value,
        sa.sales_rank AS metric_rank,
        sa.ib_lower_bound,
        sa.ib_upper_bound,
        sa.ship_mode_type,
        NULL AS reason_desc,
        NULL AS store_return_amt
    FROM sales_agg sa
    UNION ALL
    SELECT
        ra.item_sk,
        ra.order_number,
        'returns' AS metric_type,
        ra.total_return_amt AS metric_value,
        ra.return_rank AS metric_rank,
        ra.ib_lower_bound,
        ra.ib_upper_bound,
        ra.ship_mode_type,
        ra.reason_desc,
        ra.total_store_return_amt AS store_return_amt
    FROM returns_agg ra
) AS combined
ORDER BY combined.metric_value DESC
LIMIT 100
