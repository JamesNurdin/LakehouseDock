WITH sales_agg AS (
    SELECT
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_lower_bound    AS ib_lower_bound,
        ib.ib_upper_bound    AS ib_upper_bound,
        SUM(cs.cs_net_profit)            AS total_amount,
        COUNT(*)                         AS transaction_cnt,
        ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(cs.cs_net_profit) DESC) AS rank_in_band
    FROM catalog_sales cs
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450847 AND 2450914
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
),
returns_agg AS (
    SELECT
        ib.ib_income_band_sk AS ib_income_band_sk,
        ib.ib_lower_bound    AS ib_lower_bound,
        ib.ib_upper_bound    AS ib_upper_bound,
        SUM(wr.wr_net_loss)            AS total_amount,
        COUNT(*)                        AS transaction_cnt,
        ROW_NUMBER() OVER (PARTITION BY ib.ib_income_band_sk ORDER BY SUM(wr.wr_net_loss) DESC) AS rank_in_band
    FROM web_returns wr
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450847 AND 2450914
    GROUP BY
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    'sales'    AS source,
    sa.ib_income_band_sk,
    sa.ib_lower_bound,
    sa.ib_upper_bound,
    sa.total_amount,
    sa.rank_in_band
FROM sales_agg sa
UNION ALL
SELECT
    'returns'  AS source,
    ra.ib_income_band_sk,
    ra.ib_lower_bound,
    ra.ib_upper_bound,
    ra.total_amount,
    ra.rank_in_band
FROM returns_agg ra
ORDER BY ib_income_band_sk, total_amount DESC
LIMIT 100
