WITH store_sales_agg AS (
    SELECT
        ds.d_year AS year,
        hd.hd_income_band_sk AS income_band,
        SUM(ss.ss_net_paid) AS store_sales_net_paid,
        SUM(ss.ss_net_profit) AS store_sales_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_sales_discount
    FROM store_sales ss
    JOIN date_dim ds ON ss.ss_sold_date_sk = ds.d_date_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ds.d_year, hd.hd_income_band_sk
),
store_returns_agg AS (
    SELECT
        dr.d_year AS year,
        hd.hd_income_band_sk AS income_band,
        SUM(sr.sr_net_loss) AS store_returns_loss
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    GROUP BY dr.d_year, hd.hd_income_band_sk
),
web_sales_agg AS (
    SELECT
        dw.d_year AS year,
        hd.hd_income_band_sk AS income_band,
        SUM(ws.ws_net_paid) AS web_sales_net_paid,
        SUM(ws.ws_net_profit) AS web_sales_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_sales_discount
    FROM web_sales ws
    JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY dw.d_year, hd.hd_income_band_sk
),
web_returns_agg AS (
    SELECT
        drw.d_year AS year,
        hd.hd_income_band_sk AS income_band,
        SUM(wr.wr_net_loss) AS web_returns_loss
    FROM web_returns wr
    JOIN date_dim drw ON wr.wr_returned_date_sk = drw.d_date_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    GROUP BY drw.d_year, hd.hd_income_band_sk
),
catalog_sales_agg AS (
    SELECT
        dc.d_year AS year,
        hd.hd_income_band_sk AS income_band,
        SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
        SUM(cs.cs_net_profit) AS catalog_sales_net_profit,
        SUM(cs.cs_ext_discount_amt) AS catalog_sales_discount
    FROM catalog_sales cs
    JOIN date_dim dc ON cs.cs_sold_date_sk = dc.d_date_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    GROUP BY dc.d_year, hd.hd_income_band_sk
)
SELECT
    COALESCE(ss.year, sr.year, ws.year, wr.year, cs.year) AS year,
    COALESCE(ss.income_band, sr.income_band, ws.income_band, wr.income_band, cs.income_band) AS income_band,
    COALESCE(ss.store_sales_net_paid, 0) + COALESCE(ws.web_sales_net_paid, 0) + COALESCE(cs.catalog_sales_net_paid, 0) AS total_net_paid,
    COALESCE(ss.store_sales_net_profit, 0) + COALESCE(ws.web_sales_net_profit, 0) + COALESCE(cs.catalog_sales_net_profit, 0) - COALESCE(sr.store_returns_loss, 0) - COALESCE(wr.web_returns_loss, 0) AS net_profit_after_returns,
    COALESCE(ss.store_sales_discount, 0) + COALESCE(ws.web_sales_discount, 0) + COALESCE(cs.catalog_sales_discount, 0) AS total_discount_amount
FROM store_sales_agg ss
FULL OUTER JOIN store_returns_agg sr ON ss.year = sr.year AND ss.income_band = sr.income_band
FULL OUTER JOIN web_sales_agg ws ON COALESCE(ss.year, sr.year) = ws.year AND COALESCE(ss.income_band, sr.income_band) = ws.income_band
FULL OUTER JOIN web_returns_agg wr ON COALESCE(ss.year, sr.year, ws.year) = wr.year AND COALESCE(ss.income_band, sr.income_band, ws.income_band) = wr.income_band
FULL OUTER JOIN catalog_sales_agg cs ON COALESCE(ss.year, sr.year, ws.year, wr.year) = cs.year AND COALESCE(ss.income_band, sr.income_band, ws.income_band, wr.income_band) = cs.income_band
ORDER BY year, income_band
