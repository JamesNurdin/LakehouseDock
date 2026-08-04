WITH
    intersect_keys AS (
        SELECT cs.cs_item_sk AS item_sk FROM catalog_sales cs
        INTERSECT
        SELECT sr.sr_item_sk FROM store_returns sr
    ),
    except_keys AS (
        SELECT p.p_promo_sk AS promo_sk FROM promotion p
        EXCEPT
        SELECT cs.cs_promo_sk FROM catalog_sales cs
    )
SELECT
    hd.hd_demo_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.cs_order_number,
    ss.ss_ticket_number,
    p.p_promo_name,
    w.w_warehouse_name,
    rt.total_return_amt,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_demo_sk ORDER BY ss.ss_net_profit DESC) AS profit_rank,
    CASE
        WHEN cs.cs_net_paid_inc_ship_tax > 5000 THEN 'HIGH'
        ELSE 'LOW'
    END AS payment_category
FROM household_demographics hd
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN catalog_sales cs ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_sales ss ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN web_returns wr ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
CROSS JOIN LATERAL (
    SELECT SUM(sr2.sr_return_amt) AS total_return_amt
    FROM store_returns sr2
    WHERE sr2.sr_ticket_number = ss.ss_ticket_number
) rt
WHERE ss.ss_item_sk IN (
        SELECT cr2.cr_item_sk FROM catalog_returns cr2 WHERE cr2.cr_return_quantity > 0
    )
  AND ib.ib_upper_bound <= 130000
  AND p.p_channel_dmail = 'Y'
  AND cc.cc_gmt_offset BETWEEN -5.00 AND 0.00
  AND w.w_country = 'United States'
  AND cs.cs_order_number IN (SELECT item_sk FROM intersect_keys)
  AND p.p_promo_sk NOT IN (SELECT promo_sk FROM except_keys)
ORDER BY profit_rank ASC, cs.cs_order_number DESC
LIMIT 100
