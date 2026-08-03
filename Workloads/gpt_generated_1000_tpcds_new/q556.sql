/* goal: Compare high‑value web sales with large store returns by joining all seven TPC‑DS tables, categorising quantities, computing the average web‑sales amount, filtering, and showing the top records */
WITH ws_join AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        p.p_promo_name,
        w.w_warehouse_name,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        CASE WHEN ws.ws_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS qty_category
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk      -- second alias of promotion
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk  -- second alias of warehouse
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
),

sr_join AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        r.r_reason_desc,
        s.s_store_name,
        cd.cd_gender,
        CASE WHEN sr.sr_return_quantity > 3 THEN 'High' ELSE 'Low' END AS return_level
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN reason r2 ON sr.sr_reason_sk = r2.r_reason_sk      -- second alias of reason
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk          -- second alias of store
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
),

ws_only AS (
    SELECT
        ws_order_number      AS order_id,
        qty_category,
        ws_net_paid          AS net_amount,
        p_promo_name,
        w_warehouse_name,
        bill_gender          AS gender1,
        ship_gender          AS gender2,
        (SELECT avg(ws_net_paid) FROM web_sales) AS avg_net_paid
    FROM ws_join
),

sr_only AS (
    SELECT
        sr_ticket_number     AS order_id,
        return_level         AS category,
        sr_return_amt        AS net_amount,
        NULL                 AS p_promo_name,
        NULL                 AS w_warehouse_name,
        cd_gender            AS gender1,
        NULL                 AS gender2,
        (SELECT avg(ws_net_paid) FROM web_sales) AS avg_net_paid
    FROM sr_join
),

diff_ws AS (
    SELECT order_id FROM ws_only
    EXCEPT
    SELECT order_id FROM sr_only
)
SELECT
    final.order_id,
    final.category,
    final.net_amount,
    final.promo_name,
    final.warehouse_name,
    final.gender1,
    final.gender2,
    final.avg_net_paid
FROM (
    SELECT
        w.order_id,
        w.qty_category       AS category,
        w.net_amount,
        w.p_promo_name       AS promo_name,
        w.w_warehouse_name   AS warehouse_name,
        w.gender1,
        w.gender2,
        w.avg_net_paid
    FROM diff_ws d
    JOIN ws_only w ON d.order_id = w.order_id

    UNION

    SELECT
        s.order_id,
        s.category,
        s.net_amount,
        s.p_promo_name       AS promo_name,
        s.w_warehouse_name   AS warehouse_name,
        s.gender1,
        s.gender2,
        s.avg_net_paid
    FROM sr_only s
    WHERE s.net_amount > 200
) AS final
ORDER BY final.avg_net_paid DESC
LIMIT 100
