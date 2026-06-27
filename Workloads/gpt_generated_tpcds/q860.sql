WITH
    store_sales_agg AS (
        SELECT
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(ss.ss_net_profit) AS store_net_profit,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2451000
        GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    catalog_sales_agg AS (
        SELECT
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(cs.cs_net_profit) AS catalog_net_profit,
            COUNT(*) AS catalog_sales_cnt
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2451000
        GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    web_sales_agg AS (
        SELECT
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(ws.ws_net_profit) AS web_net_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2451000
        GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    store_returns_agg AS (
        SELECT
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(sr.sr_net_loss) AS store_net_loss,
            COUNT(*) AS store_returns_cnt
        FROM store_returns sr
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE sr.sr_returned_date_sk BETWEEN 2450000 AND 2451000
        GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    ),
    web_returns_agg AS (
        SELECT
            ib.ib_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(wr.wr_net_loss) AS web_net_loss,
            COUNT(*) AS web_returns_cnt
        FROM web_returns wr
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2451000
        GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    )
SELECT
    COALESCE(s.ib_income_band_sk, c.ib_income_band_sk, w.ib_income_band_sk, sr.ib_income_band_sk, wr.ib_income_band_sk) AS income_band_sk,
    COALESCE(s.ib_lower_bound, c.ib_lower_bound, w.ib_lower_bound, sr.ib_lower_bound, wr.ib_lower_bound) AS lower_bound,
    COALESCE(s.ib_upper_bound, c.ib_upper_bound, w.ib_upper_bound, sr.ib_upper_bound, wr.ib_upper_bound) AS upper_bound,
    COALESCE(s.store_net_profit, 0) AS store_net_profit,
    COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(w.web_net_profit, 0) AS web_net_profit,
    COALESCE(sr.store_net_loss, 0) AS store_net_loss,
    COALESCE(wr.web_net_loss, 0) AS web_net_loss,
    (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0) -
     COALESCE(sr.store_net_loss, 0) - COALESCE(wr.web_net_loss, 0)) AS net_profit_after_returns,
    (COALESCE(s.store_sales_cnt, 0) + COALESCE(c.catalog_sales_cnt, 0) + COALESCE(w.web_sales_cnt, 0)) AS total_sales_cnt,
    (COALESCE(sr.store_returns_cnt, 0) + COALESCE(wr.web_returns_cnt, 0)) AS total_returns_cnt
FROM store_sales_agg s
FULL OUTER JOIN catalog_sales_agg c ON s.ib_income_band_sk = c.ib_income_band_sk
FULL OUTER JOIN web_sales_agg w ON COALESCE(s.ib_income_band_sk, c.ib_income_band_sk) = w.ib_income_band_sk
FULL OUTER JOIN store_returns_agg sr ON COALESCE(s.ib_income_band_sk, c.ib_income_band_sk, w.ib_income_band_sk) = sr.ib_income_band_sk
FULL OUTER JOIN web_returns_agg wr ON COALESCE(s.ib_income_band_sk, c.ib_income_band_sk, w.ib_income_band_sk, sr.ib_income_band_sk) = wr.ib_income_band_sk
ORDER BY net_profit_after_returns DESC
LIMIT 20
