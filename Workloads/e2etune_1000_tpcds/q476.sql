WITH
sales_agg AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_net_paid_inc_ship > 500
      AND cs.cs_sold_date_sk BETWEEN 2450840 AND 2450900
    GROUP BY hd.hd_income_band_sk
),
store_returns_agg AS (
    SELECT
        s.s_store_name,
        hd.hd_income_band_sk,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        COUNT(*) AS store_returns_cnt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450840 AND 2450900
    GROUP BY s.s_store_name, hd.hd_income_band_sk
),
web_returns_agg AS (
    SELECT
        hd.hd_income_band_sk,
        SUM(wr.wr_net_loss) AS total_web_returns_loss,
        COUNT(*) AS web_returns_cnt
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450840 AND 2450900
    GROUP BY hd.hd_income_band_sk
)
SELECT
    sra.s_store_name,
    sra.hd_income_band_sk,
    COALESCE(sa.total_sales_profit, 0) AS total_sales_profit,
    COALESCE(sra.total_store_returns_loss, 0) AS total_store_returns_loss,
    COALESCE(wra.total_web_returns_loss, 0) AS total_web_returns_loss,
    (COALESCE(sa.total_sales_profit, 0) - COALESCE(sra.total_store_returns_loss, 0) - COALESCE(wra.total_web_returns_loss, 0)) AS net_contribution,
    COALESCE(sa.sales_cnt, 0) AS sales_cnt,
    COALESCE(sra.store_returns_cnt, 0) AS store_returns_cnt,
    COALESCE(wra.web_returns_cnt, 0) AS web_returns_cnt
FROM store_returns_agg sra
LEFT JOIN sales_agg sa
    ON sra.hd_income_band_sk = sa.hd_income_band_sk
LEFT JOIN web_returns_agg wra
    ON sra.hd_income_band_sk = wra.hd_income_band_sk
WHERE (COALESCE(sa.total_sales_profit, 0) > 10000
       OR COALESCE(sra.total_store_returns_loss, 0) > 0
       OR COALESCE(wra.total_web_returns_loss, 0) > 0)
ORDER BY net_contribution DESC
LIMIT 100
