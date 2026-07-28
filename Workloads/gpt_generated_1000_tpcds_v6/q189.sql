WITH store_agg AS (
    SELECT
        sr_reason_sk AS reason_sk,
        SUM(sr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM tpcds.store_returns
    WHERE sr_store_credit > 100
      AND sr_return_quantity >= 1
    GROUP BY sr_reason_sk
),
web_agg AS (
    SELECT
        wr_reason_sk AS reason_sk,
        SUM(wr_net_loss) AS net_loss,
        COUNT(*) AS cnt
    FROM tpcds.web_returns
    WHERE wr_return_quantity >= 2
      AND wr_return_amt > 20
    GROUP BY wr_reason_sk
),
reason_agg AS (
    SELECT
        reason_sk,
        SUM(net_loss) AS total_net_loss,
        SUM(cnt) AS total_cnt
    FROM (
        SELECT reason_sk, net_loss, cnt FROM store_agg
        UNION ALL
        SELECT reason_sk, net_loss, cnt FROM web_agg
    ) u
    GROUP BY reason_sk
)
SELECT
    r.r_reason_desc,
    cc.cc_name,
    cp.cp_catalog_page_number,
    cd.cd_gender,
    agg.total_net_loss,
    agg.total_cnt,
    CASE WHEN agg.total_net_loss > 10000 THEN 'Y' ELSE 'N' END AS high_loss_flag,
    (SELECT AVG(sub.total_net_loss)
     FROM (
         SELECT reason_sk, SUM(net_loss) AS total_net_loss
         FROM (
             SELECT sr_reason_sk AS reason_sk, SUM(sr_net_loss) AS net_loss
             FROM tpcds.store_returns
             WHERE sr_store_credit > 100
               AND sr_return_quantity >= 1
             GROUP BY sr_reason_sk
             UNION ALL
             SELECT wr_reason_sk AS reason_sk, SUM(wr_net_loss) AS net_loss
             FROM tpcds.web_returns
             WHERE wr_return_quantity >= 2
               AND wr_return_amt > 20
             GROUP BY wr_reason_sk
         ) u
         GROUP BY reason_sk
     ) sub) AS avg_net_loss_across_reasons
FROM tpcds.catalog_returns cr
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN tpcds.customer_demographics cd
  ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN reason_agg agg
  ON r.r_reason_sk = agg.reason_sk
WHERE cc.cc_name = 'Midwest Call Center'
  AND cp.cp_type = 'monthly'
  AND cp.cp_catalog_number IN (2, 7, 15)
  AND cd.cd_education_status = '4 yr Degree'
  AND cd.cd_purchase_estimate BETWEEN 4000 AND 8000
  AND cr.cr_return_quantity > 1
  AND cr.cr_return_amount > 50
  AND EXISTS (
        SELECT 1
        FROM tpcds.store_returns sr2
        WHERE sr2.sr_reason_sk = cr.cr_reason_sk
          AND sr2.sr_return_quantity > 0
      )
ORDER BY agg.total_net_loss DESC
LIMIT 100
