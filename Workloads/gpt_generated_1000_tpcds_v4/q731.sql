WITH income_band_desc AS (
    SELECT
        ib_income_band_sk,
        CAST(ib_lower_bound AS VARCHAR) || '-' || CAST(ib_upper_bound AS VARCHAR) AS income_range
    FROM income_band
)
,
store_channel AS (
    SELECT
        'store' AS sales_channel,
        ss.ss_sold_date_sk AS date_key,
        s.s_store_name AS location_name,
        ib.income_range,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS txn_count,
        (SELECT AVG(cs2.cs_net_paid)
         FROM catalog_sales cs2
         WHERE cs2.cs_sold_date_sk BETWEEN 2450815 AND 2451175) AS avg_catalog_net_paid
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band_desc ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2451175
    GROUP BY ss.ss_sold_date_sk, s.s_store_name, ib.income_range
    HAVING SUM(ss.ss_net_paid) > 10000
),
catalog_channel AS (
    SELECT
        'catalog' AS sales_channel,
        cs.cs_sold_date_sk AS date_key,
        cc.cc_name AS location_name,
        ib.income_range,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS txn_count,
        (SELECT AVG(cs2.cs_net_paid)
         FROM catalog_sales cs2
         WHERE cs2.cs_sold_date_sk BETWEEN 2450815 AND 2451175) AS avg_catalog_net_paid
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band_desc ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cc.cc_state = 'CA'
      AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2451175
    GROUP BY cs.cs_sold_date_sk, cc.cc_name, ib.income_range
    HAVING SUM(cs.cs_net_paid) > 10000
)
SELECT * FROM store_channel
UNION ALL
SELECT * FROM catalog_channel
ORDER BY total_net_paid DESC
LIMIT 100
