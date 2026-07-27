WITH catalog_agg AS (
    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        r.r_reason_id,
        r.r_reason_desc,
        SUM(cr.cr_net_loss)                AS catalog_net_loss,
        AVG(cr.cr_return_amount)           AS avg_catalog_return_amt,
        COUNT(*)                           AS catalog_return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_return_amount > 500
      AND cr.cr_return_ship_cost > 50
      AND cp.cp_type = 'Standard'
      AND w.w_state = 'CA'
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound,
             r.r_reason_id, r.r_reason_desc
),
store_agg AS (
    SELECT
        ib.ib_income_band_sk,
        r.r_reason_id,
        r.r_reason_desc,
        SUM(sr.sr_net_loss) AS store_net_loss,
        COUNT(*)            AS store_return_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_ship_cost > 100
      AND sr.sr_fee > 30
    GROUP BY ib.ib_income_band_sk,
             r.r_reason_id, r.r_reason_desc
),
web_agg AS (
    SELECT
        ib.ib_income_band_sk,
        r.r_reason_id,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*)            AS web_return_cnt
    FROM tpcds.web_returns wr
    JOIN tpcds.customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN tpcds.household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 1
      AND wr.wr_account_credit > 200
    GROUP BY ib.ib_income_band_sk,
             r.r_reason_id, r.r_reason_desc
)
SELECT
    ca.ib_income_band_sk,
    ca.ib_lower_bound,
    ca.ib_upper_bound,
    ca.r_reason_id,
    ca.r_reason_desc,
    ca.catalog_net_loss,
    sa.store_net_loss,
    wa.web_net_loss,
    ca.catalog_return_cnt,
    sa.store_return_cnt,
    wa.web_return_cnt,
    ca.avg_catalog_return_amt,
    (ca.catalog_net_loss + COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) AS total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY ca.ib_income_band_sk ORDER BY (ca.catalog_net_loss + COALESCE(sa.store_net_loss, 0) + COALESCE(wa.web_net_loss, 0)) DESC) AS reason_rank
FROM catalog_agg ca
LEFT JOIN store_agg sa
    ON ca.ib_income_band_sk = sa.ib_income_band_sk
   AND ca.r_reason_id = sa.r_reason_id
LEFT JOIN web_agg wa
    ON ca.ib_income_band_sk = wa.ib_income_band_sk
   AND ca.r_reason_id = wa.r_reason_id
ORDER BY total_net_loss DESC
LIMIT 100
