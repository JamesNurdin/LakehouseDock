WITH
    store_sales_agg AS (
        SELECT
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(ss.ss_net_profit) AS total_store_profit,
            COUNT(*) AS store_sales_cnt
        FROM store_sales ss
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    ),
    web_sales_agg AS (
        SELECT
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(ws.ws_net_profit) AS total_web_profit,
            COUNT(*) AS web_sales_cnt
        FROM web_sales ws
        JOIN customer c
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    ),
    returns_agg AS (
        SELECT
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            SUM(r.net_loss) FILTER (WHERE r.source = 'catalog') AS total_catalog_loss,
            SUM(r.net_loss) FILTER (WHERE r.source = 'store')   AS total_store_loss,
            SUM(r.net_loss) FILTER (WHERE r.source = 'web')    AS total_web_loss,
            COUNT(*) AS total_return_cnt
        FROM (
            SELECT cr.cr_refunded_hdemo_sk AS hd_demo_sk,
                   cr.cr_net_loss           AS net_loss,
                   'catalog'                AS source
            FROM catalog_returns cr
            UNION ALL
            SELECT sr.sr_hdemo_sk,
                   sr.sr_net_loss,
                   'store'
            FROM store_returns sr
            UNION ALL
            SELECT wr.wr_refunded_hdemo_sk,
                   wr.wr_net_loss,
                   'web'
            FROM web_returns wr
        ) r
        JOIN household_demographics hd
            ON r.hd_demo_sk = hd.hd_demo_sk
        JOIN income_band ib
            ON hd.hd_income_band_sk = ib.ib_income_band_sk
        GROUP BY ib.ib_lower_bound, ib.ib_upper_bound
    )
SELECT
    COALESCE(sa.ib_lower_bound, wa.ib_lower_bound, ra.ib_lower_bound) AS ib_lower_bound,
    COALESCE(sa.ib_upper_bound, wa.ib_upper_bound, ra.ib_upper_bound) AS ib_upper_bound,
    COALESCE(sa.total_store_profit, 0) + COALESCE(wa.total_web_profit, 0) AS total_profit,
    COALESCE(ra.total_catalog_loss, 0) + COALESCE(ra.total_store_loss, 0) + COALESCE(ra.total_web_loss, 0) AS total_loss,
    (COALESCE(sa.total_store_profit, 0) + COALESCE(wa.total_web_profit, 0)) -
    (COALESCE(ra.total_catalog_loss, 0) + COALESCE(ra.total_store_loss, 0) + COALESCE(ra.total_web_loss, 0)) AS net_impact,
    COALESCE(sa.store_sales_cnt, 0) + COALESCE(wa.web_sales_cnt, 0) AS total_sales_cnt,
    COALESCE(ra.total_return_cnt, 0) AS total_return_cnt
FROM store_sales_agg sa
FULL OUTER JOIN web_sales_agg wa
    ON sa.ib_lower_bound = wa.ib_lower_bound
   AND sa.ib_upper_bound = wa.ib_upper_bound
FULL OUTER JOIN returns_agg ra
    ON COALESCE(sa.ib_lower_bound, wa.ib_lower_bound) = ra.ib_lower_bound
   AND COALESCE(sa.ib_upper_bound, wa.ib_upper_bound) = ra.ib_upper_bound
ORDER BY net_impact DESC
