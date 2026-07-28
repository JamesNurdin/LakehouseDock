WITH ss_agg AS (
    SELECT
        ss_customer_sk,
        ss_promo_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_quantity BETWEEN 1 AND 5
      AND ss_sold_date_sk = 2451235
    GROUP BY ss_customer_sk, ss_promo_sk
)
SELECT
    c.c_customer_id,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    p.p_promo_name,
    sm.sm_type,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    SUM(sr.sr_refunded_cash) AS store_refunded_cash,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    SUM(wr.wr_refunded_cash) AS web_refunded_cash,
    ss_agg.total_sales,
    ss_agg.total_profit,
    CASE
        WHEN ss_agg.total_profit > 10000 THEN 'HIGH'
        WHEN ss_agg.total_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM ss_agg
JOIN customer c
    ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN promotion p
    ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE p.p_discount_active = 'Y'
  AND sm.sm_contract = 'qENFQ'
  AND ib.ib_upper_bound >= 50000
  AND ws.ws_net_paid_inc_tax > 2000
GROUP BY
    c.c_customer_id,
    hd.hd_buy_potential,
    ib.ib_upper_bound,
    p.p_promo_name,
    sm.sm_type,
    ss_agg.total_sales,
    ss_agg.total_profit
ORDER BY profit_category DESC, total_sales DESC
LIMIT 100
