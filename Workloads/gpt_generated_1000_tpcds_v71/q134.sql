WITH reason_filtered AS (
        SELECT DISTINCT r.r_reason_sk,
               r.r_reason_desc
        FROM reason r
        WHERE r.r_reason_desc LIKE '%damage%'
           OR r.r_reason_desc LIKE '%defect%'
    ),
    income_filtered AS (
        SELECT ib.ib_income_band_sk
        FROM income_band ib
        WHERE ib.ib_upper_bound >= 80000
          AND ib.ib_lower_bound <= 150000
    ),
    store_filtered AS (
        SELECT s.s_store_sk,
               s.s_store_name,
               s.s_tax_percentage,
               s.s_rec_end_date
        FROM store s
        WHERE s.s_tax_percentage BETWEEN 0.02 AND 0.07
          AND s.s_rec_end_date >= DATE '2000-01-01'
    ),
    base AS (
        SELECT
            cr.cr_returned_date_sk               AS returned_date_sk,
            cr.cr_net_loss                       AS net_loss,
            c.c_customer_sk                      AS c_customer_sk,
            hd.hd_demo_sk                        AS hd_demo_sk,
            r.r_reason_desc                      AS reason_desc,
            CAST(NULL AS varchar)                AS store_name,
            CAST(NULL AS decimal(5,2))           AS store_tax,
            CAST(NULL AS date)                   AS store_end_date
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN reason_filtered r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE ib.ib_income_band_sk IN (SELECT ib_income_band_sk FROM income_filtered)

        UNION ALL

        SELECT
            sr.sr_returned_date_sk               AS returned_date_sk,
            sr.sr_net_loss                       AS net_loss,
            c.c_customer_sk                      AS c_customer_sk,
            hd.hd_demo_sk                        AS hd_demo_sk,
            r.r_reason_desc                      AS reason_desc,
            s.s_store_name                       AS store_name,
            s.s_tax_percentage                   AS store_tax,
            s.s_rec_end_date                     AS store_end_date
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN reason_filtered r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN store_filtered s ON sr.sr_store_sk = s.s_store_sk
        WHERE ib.ib_income_band_sk IN (SELECT ib_income_band_sk FROM income_filtered)

        UNION ALL

        SELECT
            wr.wr_returned_date_sk               AS returned_date_sk,
            wr.wr_net_loss                       AS net_loss,
            c.c_customer_sk                      AS c_customer_sk,
            hd.hd_demo_sk                        AS hd_demo_sk,
            r.r_reason_desc                      AS reason_desc,
            CAST(NULL AS varchar)                AS store_name,
            CAST(NULL AS decimal(5,2))           AS store_tax,
            CAST(NULL AS date)                   AS store_end_date
        FROM web_returns wr
        JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN reason_filtered r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE ib.ib_income_band_sk IN (SELECT ib_income_band_sk FROM income_filtered)
    ),
    agg1 AS (
        SELECT
            store_name,
            reason_desc,
            SUM(COALESCE(net_loss, 0))                         AS total_net_loss,
            COUNT(*)                                          AS return_cnt,
            COUNT(DISTINCT c_customer_sk)                     AS distinct_customers
        FROM base
        GROUP BY ROLLUP (store_name, reason_desc)
    )
SELECT
    store_name,
    reason_desc,
    total_net_loss,
    return_cnt,
    distinct_customers,
    total_net_loss / NULLIF(return_cnt, 0) AS avg_loss_per_return
FROM agg1
WHERE total_net_loss > 1000
  AND distinct_customers >= 5
  AND (store_name IS NOT NULL OR reason_desc IS NOT NULL)
ORDER BY total_net_loss DESC
LIMIT 100
