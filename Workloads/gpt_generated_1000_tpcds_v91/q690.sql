-- Goal: Analyze combined store and web sales by date, household income band, catalog page and sales channel, applying multiple filters, calculating adjusted net paid, ranking dates within each year, and showing subtotals using ROLLUP.
WITH store_agg AS (
    SELECT
        ss_sold_date_sk AS date_sk,
        ss_hdemo_sk AS hd_demo_sk,
        SUM(ss_net_paid) AS net_paid,
        SUM(ss_net_profit) AS net_profit,
        COUNT(*) AS txn_count
    FROM store_sales
    WHERE ss_quantity > 1
      AND EXISTS (
          SELECT 1
          FROM catalog_page cp
          JOIN date_dim d2 ON cp.cp_start_date_sk = d2.d_date_sk
          WHERE d2.d_date_sk = store_sales.ss_sold_date_sk
            AND cp.cp_catalog_number IN (9, 11)
      )
    GROUP BY ss_sold_date_sk, ss_hdemo_sk
),
web_agg AS (
    SELECT
        ws_sold_date_sk AS date_sk,
        ws_bill_hdemo_sk AS hd_demo_sk,
        ws_web_site_sk AS site_sk,
        SUM(ws_net_paid) AS net_paid,
        SUM(ws_net_profit) AS net_profit,
        COUNT(*) AS txn_count
    FROM web_sales
    WHERE ws_quantity > 1
      AND ws_ext_discount_amt < 500
    GROUP BY ws_sold_date_sk, ws_bill_hdemo_sk, ws_web_site_sk
),
combined AS (
    SELECT
        date_sk,
        hd_demo_sk,
        NULL AS site_sk,
        net_paid,
        net_profit,
        txn_count,
        'store' AS channel
    FROM store_agg
    UNION ALL
    SELECT
        date_sk,
        hd_demo_sk,
        site_sk,
        net_paid,
        net_profit,
        txn_count,
        'web' AS channel
    FROM web_agg
),
joined AS (
    SELECT
        d.d_date,
        d.d_year,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        cp.cp_catalog_number,
        cp.cp_type,
        ws.web_name,
        ws.web_state,
        cs.channel,
        cs.net_paid,
        cs.net_profit,
        cs.txn_count,
        CASE
            WHEN cs.channel = 'store' THEN cs.net_paid
            ELSE cs.net_paid * 0.95
        END AS adjusted_net_paid,
        (
            SELECT MAX(c2.net_paid)
            FROM combined c2
            WHERE c2.date_sk = cs.date_sk
        ) AS max_net_paid_same_date
    FROM combined cs
    LEFT JOIN date_dim d ON cs.date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd ON cs.hd_demo_sk = hd.hd_demo_sk
    LEFT JOIN web_site ws ON cs.site_sk = ws.web_site_sk
    FULL OUTER JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
    WHERE
        d.d_year = 2001
        AND hd.hd_income_band_sk BETWEEN 5 AND 10
        AND (ws.web_state = 'CA' OR cs.channel = 'store')
        AND cp.cp_type = 'ONLINE'
        AND cs.net_paid > 1000
),
aggregated AS (
    SELECT
        d_year,
        d_date,
        hd_income_band_sk,
        cp_catalog_number,
        channel,
        SUM(adjusted_net_paid) AS total_adjusted_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(txn_count) AS total_txn_count
    FROM joined
    GROUP BY ROLLUP (d_year, d_date, hd_income_band_sk, cp_catalog_number, channel)
)
SELECT
    d_year,
    d_date,
    hd_income_band_sk,
    cp_catalog_number,
    channel,
    total_adjusted_net_paid,
    total_net_profit,
    total_txn_count,
    RANK() OVER (PARTITION BY d_year ORDER BY total_adjusted_net_paid DESC) AS sales_rank
FROM aggregated
ORDER BY total_adjusted_net_paid DESC
LIMIT 100
