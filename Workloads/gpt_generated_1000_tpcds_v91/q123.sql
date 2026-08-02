WITH thought_demo AS (
    SELECT DISTINCT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
    WHERE regexp_like(wsi.web_mkt_desc, '(?i)thoughts')
      AND wsi.web_mkt_desc LIKE '%thoughts%'
      AND substring(wsi.web_mkt_desc, 1, 4) = 'Home'
),
technical_demo AS (
    SELECT DISTINCT hd.hd_demo_sk
    FROM household_demographics hd
    JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
    WHERE regexp_like(wsi.web_mkt_desc, '(?i)technical')
),
thought_only_demo AS (
    SELECT hd_demo_sk FROM thought_demo
    EXCEPT
    SELECT hd_demo_sk FROM technical_demo
)
SELECT
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN ib.ib_lower_bound >= 100000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 50000 THEN 'Mid Income'
        ELSE 'Low Income'
    END AS income_category,
    CONCAT(hd.hd_buy_potential, '-', CAST(ib.ib_income_band_sk AS VARCHAR)) AS buy_potential_key,
    COUNT(DISTINCT hd.hd_demo_sk) AS demo_count,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_net_profit ELSE 0 END) AS positive_profit,
    SUM(CASE WHEN ws.ws_net_profit <= 0 THEN ws.ws_net_profit ELSE 0 END) AS non_positive_profit,
    MAX(regexp_extract(wsi.web_mkt_desc, '([A-Za-z]+)', 1)) AS first_word_mkt_desc,
    MIN(substring(wsi.web_mkt_desc, 1, 5)) AS mkt_desc_start5
FROM thought_only_demo tod
JOIN household_demographics hd ON tod.hd_demo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN web_sales ws ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_site wsi ON ws.ws_web_site_sk = wsi.web_site_sk
GROUP BY
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
        WHEN ib.ib_lower_bound >= 100000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 50000 THEN 'Mid Income'
        ELSE 'Low Income'
    END,
    CONCAT(hd.hd_buy_potential, '-', CAST(ib.ib_income_band_sk AS VARCHAR))
ORDER BY total_net_profit DESC
LIMIT 20
