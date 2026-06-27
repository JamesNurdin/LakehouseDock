WITH
    store_sales_agg AS (
        SELECT
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(ss.ss_net_profit) AS store_net_profit
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    store_returns_agg AS (
        SELECT
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(sr.sr_net_loss) AS store_return_loss
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    catalog_sales_agg AS (
        SELECT
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(cs.cs_net_profit) AS catalog_net_profit
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    catalog_returns_agg AS (
        SELECT
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(cr.cr_net_loss) AS catalog_return_loss
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    web_sales_agg AS (
        SELECT
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(ws.ws_net_profit) AS web_net_profit
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    web_returns_agg AS (
        SELECT
            d.d_year,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(wr.wr_net_loss) AS web_return_loss
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE d.d_year = 2001
        GROUP BY d.d_year, ib.ib_lower_bound, ib.ib_upper_bound
    )
SELECT
    COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year, wr.d_year)               AS d_year,
    COALESCE(ss.ib_lower_bound, sr.ib_lower_bound, cs.ib_lower_bound, cr.ib_lower_bound, ws.ib_lower_bound, wr.ib_lower_bound) AS ib_lower_bound,
    COALESCE(ss.ib_upper_bound, sr.ib_upper_bound, cs.ib_upper_bound, cr.ib_upper_bound, ws.ib_upper_bound, wr.ib_upper_bound) AS ib_upper_bound,
    COALESCE(ss.store_net_profit, 0)          AS store_net_profit,
    COALESCE(cs.catalog_net_profit, 0)        AS catalog_net_profit,
    COALESCE(ws.web_net_profit, 0)            AS web_net_profit,
    COALESCE(sr.store_return_loss, 0)         AS store_return_loss,
    COALESCE(cr.catalog_return_loss, 0)       AS catalog_return_loss,
    COALESCE(wr.web_return_loss, 0)           AS web_return_loss,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
     - COALESCE(sr.store_return_loss, 0) - COALESCE(cr.catalog_return_loss, 0) - COALESCE(wr.web_return_loss, 0)
    )                                         AS total_net_profit
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr
    ON ss.d_year = sr.d_year
   AND ss.ib_lower_bound = sr.ib_lower_bound
   AND ss.ib_upper_bound = sr.ib_upper_bound
FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.d_year, sr.d_year) = cs.d_year
   AND COALESCE(ss.ib_lower_bound, sr.ib_lower_bound) = cs.ib_lower_bound
   AND COALESCE(ss.ib_upper_bound, sr.ib_upper_bound) = cs.ib_upper_bound
FULL OUTER JOIN catalog_returns_agg cr
    ON COALESCE(ss.d_year, sr.d_year, cs.d_year) = cr.d_year
   AND COALESCE(ss.ib_lower_bound, sr.ib_lower_bound, cs.ib_lower_bound) = cr.ib_lower_bound
   AND COALESCE(ss.ib_upper_bound, sr.ib_upper_bound, cs.ib_upper_bound) = cr.ib_upper_bound
FULL OUTER JOIN web_sales_agg ws
    ON COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year) = ws.d_year
   AND COALESCE(ss.ib_lower_bound, sr.ib_lower_bound, cs.ib_lower_bound, cr.ib_lower_bound) = ws.ib_lower_bound
   AND COALESCE(ss.ib_upper_bound, sr.ib_upper_bound, cs.ib_upper_bound, cr.ib_upper_bound) = ws.ib_upper_bound
FULL OUTER JOIN web_returns_agg wr
    ON COALESCE(ss.d_year, sr.d_year, cs.d_year, cr.d_year, ws.d_year) = wr.d_year
   AND COALESCE(ss.ib_lower_bound, sr.ib_lower_bound, cs.ib_lower_bound, cr.ib_lower_bound, ws.ib_lower_bound) = wr.ib_lower_bound
   AND COALESCE(ss.ib_upper_bound, sr.ib_upper_bound, cs.ib_upper_bound, cr.ib_upper_bound, ws.ib_upper_bound) = wr.ib_upper_bound
ORDER BY d_year, ib_lower_bound
