WITH joined_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_ship_mode_sk,
        sm.sm_carrier,
        ws.ws_warehouse_sk,
        w.w_warehouse_name,
        ws.ws_promo_sk,
        p.p_promo_name,
        ws.ws_bill_customer_sk,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_gender,
        hd.hd_buy_potential,
        ws.ws_web_page_sk,
        wp.wp_type,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr_reason.r_reason_id AS sr_reason_id,
        sr_reason.r_reason_desc AS sr_reason_desc,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr_reason.r_reason_id AS wr_reason_id,
        wr_reason.r_reason_desc AS wr_reason_desc
    FROM web_sales ws
    INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    INNER JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_customer_sk = c.c_customer_sk
    LEFT JOIN reason sr_reason ON sr.sr_reason_sk = sr_reason.r_reason_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk AND wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN reason wr_reason ON wr.wr_reason_sk = wr_reason.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2451247 AND 2452000
      AND sm.sm_carrier = 'FEDEX'
      AND c.c_birth_year = 1972
      AND i.i_current_price > 100
      AND p.p_discount_active = 'Y'
),
aggregated_data AS (
    SELECT
        jd.c_customer_sk,
        jd.c_first_name,
        jd.c_last_name,
        jd.c_birth_year,
        jd.i_category,
        jd.i_brand,
        SUM(jd.ws_ext_sales_price) AS total_sales,
        SUM(jd.ws_net_profit) AS total_profit,
        COUNT(DISTINCT jd.ws_order_number) AS order_count,
        AVG(jd.ws_quantity) AS avg_quantity,
        SUM(jd.sr_return_amt) AS total_store_return_amt,
        SUM(jd.wr_return_amt) AS total_web_return_amt
    FROM joined_data jd
    GROUP BY
        jd.c_customer_sk,
        jd.c_first_name,
        jd.c_last_name,
        jd.c_birth_year,
        jd.i_category,
        jd.i_brand
)
SELECT
    ad.c_first_name,
    ad.c_last_name,
    ad.c_birth_year,
    ad.i_category,
    ad.i_brand,
    ad.total_sales,
    ad.total_profit,
    ad.order_count,
    ad.avg_quantity,
    CASE
        WHEN ad.total_profit > 10000 THEN 'HIGH'
        WHEN ad.total_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    (SELECT COUNT(*) FROM store_returns sr2 WHERE sr2.sr_customer_sk = ad.c_customer_sk) AS total_store_returns,
    (SELECT COALESCE(SUM(wr2.wr_return_amt), 0) FROM web_returns wr2 WHERE wr2.wr_refunded_customer_sk = ad.c_customer_sk) AS total_web_return_amount,
    SUM(ad.total_profit) OVER (PARTITION BY ad.i_category ORDER BY ad.total_sales ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit_by_category,
    RANK() OVER (ORDER BY ad.total_profit DESC) AS profit_rank
FROM aggregated_data ad
WHERE (SELECT COALESCE(SUM(wr3.wr_return_amt), 0) FROM web_returns wr3 WHERE wr3.wr_refunded_customer_sk = ad.c_customer_sk) > 0
ORDER BY ad.total_profit DESC
LIMIT 100
