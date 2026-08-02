WITH item_price_stats AS (
    SELECT
        i.i_item_sk,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM
        catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY
        i.i_item_sk
)
SELECT
    s.s_store_name,
    ib.ib_income_band_sk,
    r.r_reason_desc,
    COUNT(DISTINCT cs.cs_order_number) AS orders_count,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cs.cs_sales_price) AS avg_sales_price,
    SUM(wr.wr_return_amt) AS total_web_return_amt,
    MAX(i.i_current_price) AS max_item_price,
    MIN(cs.cs_net_paid) AS min_net_paid,
    item_price_stats.avg_sales_price AS item_avg_sales_price
FROM
    store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN item_price_stats ON i.i_item_sk = item_price_stats.i_item_sk
WHERE
    ib.ib_upper_bound BETWEEN 50000 AND 150000
    AND i.i_current_price > 50.00
    AND r.r_reason_desc = 'Did not like the color'
    AND cs.cs_sales_price > 70.00
    AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
          AND wr2.wr_return_amt > 20.00
    )
    AND cs.cs_net_paid > (
        SELECT AVG(cs3.cs_net_paid)
        FROM catalog_sales cs3
        WHERE cs3.cs_item_sk = i.i_item_sk
    )
GROUP BY
    s.s_store_name,
    ib.ib_income_band_sk,
    r.r_reason_desc,
    item_price_stats.avg_sales_price
ORDER BY
    total_return_amount DESC,
    orders_count DESC
LIMIT 100
