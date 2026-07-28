WITH sales_base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_hdemo_sk,
        d.d_date,
        d.d_year,
        hd.hd_vehicle_count,
        hd.hd_dep_count,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cc.cc_name,
        cc.cc_class,
        ws.web_name,
        ws.web_market_manager
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31'
      AND d.d_year = 2002
      AND hd.hd_vehicle_count >= 0
      AND ib.ib_lower_bound >= 20000
      AND cc.cc_class IS NOT NULL
      AND ws.web_market_manager IN ('Joe George', 'Kelvin Lynch')
      AND ss.ss_net_profit > 0
),
band_avg AS (
    SELECT
        hd.hd_income_band_sk,
        AVG(ss.ss_net_profit) AS avg_profit_band
    FROM store_sales ss
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT
    sb.d_date,
    sb.cc_name,
    sb.web_name,
    sb.ss_quantity,
    sb.ss_net_paid,
    sb.ss_net_profit,
    CASE
        WHEN sb.ss_net_profit > ba.avg_profit_band THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY sb.cc_name ORDER BY sb.ss_net_paid DESC) AS sales_rank_per_cc,
    SUM(sb.ss_net_paid) OVER (PARTITION BY sb.cc_name ORDER BY sb.d_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3day_net_paid
FROM sales_base sb
JOIN band_avg ba
    ON sb.hd_income_band_sk = ba.hd_income_band_sk
WHERE sb.cc_class = 'Corporate'                -- additional predicate
  AND sb.web_name LIKE '%Site%'                 -- additional predicate
ORDER BY profit_category, sales_rank_per_cc
LIMIT 100
