WITH store_agg AS (
    SELECT
        sr_customer_sk,
        sr_reason_sk,
        SUM(sr_net_loss) AS store_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    GROUP BY sr_customer_sk, sr_reason_sk
)
SELECT
    cc.cc_market_manager,
    r1.r_reason_desc,
    SUM(sa.store_loss) AS total_store_loss,
    SUM(cr.cr_net_loss) AS total_catalog_loss,
    SUM(wr.wr_net_loss) AS total_web_loss,
    (SUM(sa.store_loss) + SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_loss,
    COUNT(DISTINCT sa.sr_customer_sk) AS unique_customers,
    (
        SELECT MAX(cc2.cc_gmt_offset)
        FROM call_center cc2
        WHERE cc2.cc_market_manager = cc.cc_market_manager
    ) AS max_gmt_offset
FROM store_agg sa
JOIN store_returns sr
    ON sr.sr_customer_sk = sa.sr_customer_sk
   AND sr.sr_reason_sk = sa.sr_reason_sk
JOIN customer c1
    ON sr.sr_customer_sk = c1.c_customer_sk
JOIN household_demographics hd1
    ON sr.sr_hdemo_sk = hd1.hd_demo_sk
JOIN reason r1
    ON sr.sr_reason_sk = r1.r_reason_sk
JOIN date_dim d_store
    ON sr.sr_returned_date_sk = d_store.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c1.c_customer_sk
JOIN reason r2
    ON cr.cr_reason_sk = r2.r_reason_sk
JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN date_dim d_catalog
    ON cr.cr_returned_date_sk = d_catalog.d_date_sk
JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c1.c_customer_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN reason r3
    ON wr.wr_reason_sk = r3.r_reason_sk
JOIN date_dim d_web
    ON wr.wr_returned_date_sk = d_web.d_date_sk
JOIN date_dim d_cc_open
    ON cc.cc_open_date_sk = d_cc_open.d_date_sk
WHERE d_store.d_year = 2022
  AND d_catalog.d_year = 2022
  AND d_web.d_year = 2022
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c1.c_customer_sk
          AND wp2.wp_url LIKE '%promo%'
    )
GROUP BY cc.cc_market_manager, r1.r_reason_desc, cc.cc_market_manager
ORDER BY total_loss DESC
LIMIT 100
