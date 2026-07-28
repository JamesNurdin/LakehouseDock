WITH demo_agg AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(wr.wr_return_amt) AS total_web_returns,
        COUNT(DISTINCT cs.cs_order_number) AS cnt_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_tickets,
        COUNT(DISTINCT wr.wr_order_number) AS cnt_returns,
        SUM(CASE WHEN r.r_reason_desc LIKE '%price%' THEN 1 ELSE 0 END) AS cnt_price_reason
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE cs.cs_ext_discount_amt > 500
      AND cs.cs_ext_tax < 500
      AND ib.ib_upper_bound >= 100000
      AND cs.cs_ext_sales_price > 0
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc IS NOT NULL
    GROUP BY
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound,
    AVG(total_catalog_sales) AS avg_catalog_sales,
    AVG(total_store_sales) AS avg_store_sales,
    AVG(total_web_returns) AS avg_web_returns,
    SUM(cnt_orders) AS total_orders,
    SUM(cnt_price_reason) AS total_price_related_returns
FROM demo_agg
WHERE total_catalog_sales > 10000
GROUP BY
    ib_income_band_sk,
    ib_lower_bound,
    ib_upper_bound
HAVING SUM(cnt_orders) > 10
ORDER BY avg_catalog_sales DESC
LIMIT 100
