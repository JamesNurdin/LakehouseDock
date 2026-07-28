WITH base AS (
    SELECT
        d.d_year,
        ws.ws_web_site_sk AS ws_web_site_sk,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(sr.sr_net_loss) AS total_returns_loss
    FROM date_dim d
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = ss.ss_hdemo_sk
    LEFT JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND ib.ib_upper_bound <= 120000
      AND wsite.web_open_date_sk <= d.d_date_sk
      AND wsite.web_close_date_sk >= d.d_date_sk
      AND r.r_reason_desc = 'Damaged'
      AND ws.ws_quantity > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_sold_date_sk = d.d_date_sk
            AND cs2.cs_net_paid_inc_tax > 1000
      )
    GROUP BY d.d_year, ws.ws_web_site_sk
)
SELECT
    b.d_year,
    b.ws_web_site_sk,
    b.web_profit,
    b.store_profit,
    b.catalog_profit,
    b.total_returns_loss,
    (b.web_profit + b.store_profit + b.catalog_profit - b.total_returns_loss) AS net_total_profit,
    (b.web_profit + b.store_profit + b.catalog_profit - b.total_returns_loss) / NULLIF(cnt.cnt, 0) AS avg_profit_per_year
FROM base b
JOIN (
    SELECT d_year, COUNT(*) AS cnt
    FROM base
    GROUP BY d_year
) cnt ON cnt.d_year = b.d_year
ORDER BY net_total_profit DESC
LIMIT 100
