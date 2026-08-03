WITH sr_agg AS (
    SELECT
        sr_item_sk,
        sr_cdemo_sk,
        sr_reason_sk,
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_return_time_sk IN (41617, 48082, 40372)
    GROUP BY sr_item_sk, sr_cdemo_sk, sr_reason_sk, sr_customer_sk
)

SELECT
    CASE WHEN cd.cd_dep_count > 2 THEN 'LargeFamily' ELSE 'SmallFamily' END AS family_type,
    i.i_brand,
    r.r_reason_desc,
    SUM(sr_agg.total_return_amt) AS sum_return_amt,
    AVG(sr_agg.total_net_loss) AS avg_net_loss,
    COUNT(*) AS cnt_returns,
    MIN(i.i_current_price) AS min_price,
    MAX(i.i_current_price) AS max_price
FROM sr_agg
JOIN item i ON i.i_item_sk = sr_agg.sr_item_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = sr_agg.sr_cdemo_sk
JOIN reason r ON r.r_reason_sk = sr_agg.sr_reason_sk
WHERE i.i_current_price > 20
  AND i.i_size = 'large'
  AND cd.cd_marital_status = 'M'
  AND r.r_reason_desc = 'Damaged'
  AND sr_agg.total_return_amt > 100
  AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_customer_sk = sr_agg.sr_customer_sk
          AND sr2.sr_return_amt > 50
    )
GROUP BY
    CASE WHEN cd.cd_dep_count > 2 THEN 'LargeFamily' ELSE 'SmallFamily' END,
    i.i_brand,
    r.r_reason_desc

UNION

SELECT
    CASE WHEN cd.cd_dep_count > 2 THEN 'LargeFamily' ELSE 'SmallFamily' END AS family_type,
    i.i_brand,
    r.r_reason_desc,
    SUM(sr_agg.total_return_amt) AS sum_return_amt,
    AVG(sr_agg.total_net_loss) AS avg_net_loss,
    COUNT(*) AS cnt_returns,
    MIN(i.i_current_price) AS min_price,
    MAX(i.i_current_price) AS max_price
FROM sr_agg
JOIN item i ON i.i_item_sk = sr_agg.sr_item_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = sr_agg.sr_cdemo_sk
JOIN reason r ON r.r_reason_sk = sr_agg.sr_reason_sk
WHERE i.i_current_price > 30
  AND i.i_size = 'medium'
  AND cd.cd_marital_status = 'M'
  AND r.r_reason_desc = 'Defective'
  AND sr_agg.total_return_amt > 100
  AND EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_customer_sk = sr_agg.sr_customer_sk
          AND sr2.sr_return_amt > 50
    )
GROUP BY
    CASE WHEN cd.cd_dep_count > 2 THEN 'LargeFamily' ELSE 'SmallFamily' END,
    i.i_brand,
    r.r_reason_desc

ORDER BY sum_return_amt DESC, family_type ASC
LIMIT 100
