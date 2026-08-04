WITH
    cs_agg AS (
        SELECT
            cs.cs_call_center_sk,
            cs.cs_catalog_page_sk,
            cs.cs_promo_sk,
            cs.cs_bill_hdemo_sk,
            SUM(cs.cs_net_paid) AS total_net_paid,
            AVG(cs.cs_ext_discount_amt) AS avg_discount,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        WHERE cs.cs_net_paid > 100
          AND cs.cs_list_price >= 20
        GROUP BY cs.cs_call_center_sk, cs.cs_catalog_page_sk, cs.cs_promo_sk, cs.cs_bill_hdemo_sk
    ),
    sr_agg AS (
        SELECT
            sr.sr_store_sk,
            SUM(sr.sr_return_amt) AS total_return_amt,
            SUM(sr.sr_net_loss) AS total_net_loss,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        WHERE sr.sr_return_amt > 10
          AND sr.sr_return_quantity > 0
        GROUP BY sr.sr_store_sk
    ),
    missing_stores AS (
        SELECT s_store_sk FROM store
        EXCEPT
        SELECT sr_store_sk FROM store_returns
    ),
    store_full AS (
        SELECT s.*, sr.sr_hdemo_sk, sr.sr_store_sk
        FROM store s
        FULL OUTER JOIN store_returns sr ON sr.sr_store_sk = s.s_store_sk
    )
SELECT
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    p.p_promo_name,
    hd.hd_buy_potential,
    sf.s_store_name,
    cs.total_net_paid,
    cs.avg_discount,
    cs.sales_cnt,
    sr.total_return_amt,
    sr.return_cnt,
    (cs.total_net_paid - COALESCE(sr.total_return_amt, 0)) AS net_contribution,
    CASE WHEN ms.s_store_sk IS NOT NULL THEN 1 ELSE 0 END AS is_missing_store,
    SUM(wr.wr_return_amt) AS web_return_total
FROM cs_agg cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_full sf ON sf.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN sr_agg sr ON sf.sr_store_sk = sr.sr_store_sk
LEFT JOIN missing_stores ms ON sf.s_store_sk = ms.s_store_sk
LEFT JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE cc.cc_state = 'CA'
  AND cp.cp_department = 'Electronics'
  AND p.p_discount_active = 'Y'
  AND hd.hd_vehicle_count > 0
  AND (cs.total_net_paid - COALESCE(sr.total_return_amt, 0)) > 500
GROUP BY
    cc.cc_call_center_id,
    cp.cp_catalog_page_id,
    p.p_promo_name,
    hd.hd_buy_potential,
    sf.s_store_name,
    cs.total_net_paid,
    cs.avg_discount,
    cs.sales_cnt,
    sr.total_return_amt,
    sr.return_cnt,
    (cs.total_net_paid - COALESCE(sr.total_return_amt, 0)),
    CASE WHEN ms.s_store_sk IS NOT NULL THEN 1 ELSE 0 END
ORDER BY net_contribution DESC
LIMIT 100
