WITH agg AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        s.s_store_name AS store_name,
        r.r_reason_desc AS reason_desc,
        sm.sm_type AS ship_type,
        cd.cd_gender AS gender,
        c.c_preferred_cust_flag AS preferred_flag,
        SUM(ss.ss_net_profit) AS sum_store_profit,
        SUM(ws.ws_net_profit) AS sum_web_profit,
        SUM(cr.cr_net_loss) AS sum_catalog_loss,
        SUM(wr.wr_net_loss) AS sum_web_return_loss,
        COUNT(*) AS txn_cnt
    FROM
        catalog_returns cr
        JOIN customer c
            ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd
            ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        JOIN store_sales ss
            ON ss.ss_customer_sk = c.c_customer_sk
            AND ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p
            ON ss.ss_promo_sk = p.p_promo_sk
        JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_promo_sk = p.p_promo_sk
            AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN web_returns wr
            ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
            AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
            AND wr.wr_reason_sk = r.r_reason_sk
            AND wr.wr_item_sk = ws.ws_item_sk
    WHERE
        ss.ss_sold_date_sk BETWEEN 2451910 AND 2451915
        AND ws.ws_sold_date_sk BETWEEN 2451910 AND 2451915
        AND cr.cr_returned_date_sk BETWEEN 2451910 AND 2451915
        AND wr.wr_returned_date_sk BETWEEN 2451910 AND 2451915
        AND p.p_channel_demo = 'N'
        AND sm.sm_type = 'AIR'
        AND cd.cd_gender = 'M'
        AND c.c_preferred_cust_flag = 'Y'
        AND s.s_state = 'CA'
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        s.s_store_name,
        r.r_reason_desc,
        sm.sm_type,
        cd.cd_gender,
        c.c_preferred_cust_flag
)
SELECT
    promo_id,
    promo_name,
    store_name,
    reason_desc,
    ship_type,
    gender,
    preferred_flag,
    sum_store_profit,
    sum_web_profit,
    sum_catalog_loss,
    sum_web_return_loss,
    txn_cnt,
    (sum_store_profit + sum_web_profit - sum_catalog_loss - sum_web_return_loss) AS net_total_profit,
    (sum_store_profit + sum_web_profit - sum_catalog_loss - sum_web_return_loss) / NULLIF(txn_cnt, 0) AS avg_profit_per_txn
FROM agg
WHERE (sum_store_profit + sum_web_profit - sum_catalog_loss - sum_web_return_loss) > (
    SELECT AVG(
        a.sum_store_profit + a.sum_web_profit - a.sum_catalog_loss - a.sum_web_return_loss
    )
    FROM agg a
)
ORDER BY net_total_profit DESC
LIMIT 100
