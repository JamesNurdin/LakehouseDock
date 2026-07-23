WITH ss AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_sold_time_sk AS time_sk,
        ss.ss_cdemo_sk AS cdemo_sk,
        ss.ss_promo_sk AS promo_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    GROUP BY ss.ss_sold_date_sk, ss.ss_sold_time_sk, ss.ss_cdemo_sk, ss.ss_promo_sk
),
cs AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_sold_time_sk AS time_sk,
        cs.cs_bill_cdemo_sk AS cdemo_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_call_center_sk AS call_center_sk,
        SUM(cs.cs_net_paid) AS catalog_net_paid,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk, cs.cs_sold_time_sk, cs.cs_bill_cdemo_sk, cs.cs_promo_sk, cs.cs_call_center_sk
),
ws AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_sold_time_sk AS time_sk,
        ws.ws_bill_cdemo_sk AS cdemo_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_web_site_sk AS web_site_sk,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_sold_time_sk, ws.ws_bill_cdemo_sk, ws.ws_promo_sk, ws.ws_web_site_sk
),
cr AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_returned_time_sk AS time_sk,
        cr.cr_refunded_cdemo_sk AS cdemo_sk,
        cr.cr_reason_sk AS reason_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_txn_cnt
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_returned_time_sk, cr.cr_refunded_cdemo_sk, cr.cr_reason_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    cc.cc_name,
    wsite.web_name,
    r.r_reason_desc,
    SUM(ss.store_net_paid) AS total_store_net_paid,
    SUM(cs.catalog_net_paid) AS total_catalog_net_paid,
    SUM(ws.web_net_paid) AS total_web_net_paid,
    SUM(cr.total_return_amount) AS total_return_amount,
    SUM(ss.store_net_profit + cs.catalog_net_profit + ws.web_net_profit) AS total_net_profit,
    COUNT(DISTINCT ss.date_sk) AS distinct_dates
FROM ss
JOIN cs
    ON ss.date_sk = cs.date_sk
    AND ss.time_sk = cs.time_sk
    AND ss.cdemo_sk = cs.cdemo_sk
    AND ss.promo_sk = cs.promo_sk
JOIN ws
    ON ss.date_sk = ws.date_sk
    AND ss.time_sk = ws.time_sk
    AND ss.cdemo_sk = ws.cdemo_sk
    AND ss.promo_sk = ws.promo_sk
JOIN cr
    ON ss.date_sk = cr.date_sk
    AND ss.time_sk = cr.time_sk
    AND ss.cdemo_sk = cr.cdemo_sk
JOIN date_dim d
    ON ss.date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.time_sk = t.t_time_sk
JOIN promotion p
    ON ss.promo_sk = p.p_promo_sk
JOIN call_center cc
    ON cs.call_center_sk = cc.cc_call_center_sk
JOIN web_site wsite
    ON ws.web_site_sk = wsite.web_site_sk
JOIN reason r
    ON cr.reason_sk = r.r_reason_sk
JOIN customer_demographics cd
    ON ss.cdemo_sk = cd.cd_demo_sk
WHERE d.d_date = DATE '2000-01-15'
  AND d.d_dom = 12
  AND p.p_discount_active = 'Y'
  AND cc.cc_state = 'CA'
  AND t.t_hour = 13
  AND EXISTS (
        SELECT 1
        FROM inventory i
        WHERE i.inv_date_sk = d.d_date_sk
          AND i.inv_quantity_on_hand > 0
    )
GROUP BY
    d.d_year,
    d.d_month_seq,
    p.p_promo_name,
    cc.cc_name,
    wsite.web_name,
    r.r_reason_desc
ORDER BY
    d.d_year,
    d.d_month_seq,
    total_store_net_paid DESC
