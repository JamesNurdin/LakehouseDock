WITH agg_sales_returns AS (
    SELECT
        p.p_promo_id,
        sm.sm_carrier,
        w.w_state,
        c.c_salutation,
        cd.cd_gender,
        hd.hd_buy_potential,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(sr.sr_net_loss) AS total_returns_loss,
        COUNT(DISTINCT ws.ws_order_number) AS orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_tickets
    FROM web_sales ws
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE
        c.c_salutation IN ('Mr.', 'Mrs.', 'Dr.')
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '501-1000'
        AND sm.sm_carrier = 'MSC'
        AND w.w_state = 'CA'
        AND p.p_discount_active = 'Y'
    GROUP BY
        p.p_promo_id,
        sm.sm_carrier,
        w.w_state,
        c.c_salutation,
        cd.cd_gender,
        hd.hd_buy_potential
    HAVING
        SUM(ws.ws_ext_sales_price) > 100000
        AND SUM(sr.sr_net_loss) < 50000
)
SELECT
    a.p_promo_id,
    a.total_sales,
    a.total_returns_loss,
    a.total_sales - a.total_returns_loss AS net_sales,
    a.orders,
    a.return_tickets,
    ROUND((a.total_sales - a.total_returns_loss) / NULLIF(a.orders, 0), 2) AS avg_net_per_order
FROM agg_sales_returns a
WHERE a.p_promo_id IN (
    SELECT p2.p_promo_id
    FROM promotion p2
    WHERE p2.p_cost > 10
)
ORDER BY net_sales DESC
LIMIT 100
