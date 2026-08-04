WITH promo_sales AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_channel_catalog,
        ss.ss_ext_discount_amt,
        ss.ss_net_paid,
        ws.ws_net_paid_inc_ship,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY ws.ws_net_paid_inc_ship DESC) AS rn_promo
    FROM promotion AS p
    JOIN store_sales AS ss
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN (
        SELECT *
        FROM web_sales
        TABLESAMPLE BERNOULLI (10)
    ) AS ws
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site AS wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE p.p_channel_catalog = 'N'
      AND ss.ss_ext_discount_amt > 100
      AND wsite.web_rec_end_date > DATE '2000-01-01'
),
returns_filtered AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_ship_cost,
        wr.wr_net_loss
    FROM web_returns AS wr
    WHERE wr.wr_return_ship_cost < 500
      AND wr.wr_reversed_charge > 20
      AND wr.wr_returning_hdemo_sk IN (2641, 692, 2202)
),
joined_all AS (
    SELECT
        ps.p_promo_id,
        ps.p_channel_catalog,
        ps.ss_ext_discount_amt,
        ps.ws_net_paid_inc_ship,
        rf.wr_return_ship_cost,
        rf.wr_net_loss,
        ps.rn_promo,
        ps.ws_order_number,
        ps.ws_item_sk
    FROM promo_sales AS ps
    JOIN returns_filtered AS rf
        ON rf.wr_order_number = ps.ws_order_number
       AND rf.wr_item_sk = ps.ws_item_sk
),
sub1 AS (
    SELECT p_promo_id
    FROM promo_sales
    WHERE rn_promo = 1
),
sub2 AS (
    SELECT p_promo_id
    FROM joined_all
    WHERE wr_net_loss > 0
)
SELECT
    ja.p_promo_id,
    ja.p_channel_catalog,
    ja.ss_ext_discount_amt,
    ja.ws_net_paid_inc_ship,
    ja.wr_return_ship_cost,
    ja.wr_net_loss,
    ja.rn_promo,
    CASE WHEN ja.wr_net_loss > 0 THEN 'LOSS' ELSE 'NO LOSS' END AS loss_flag
FROM joined_all AS ja
WHERE ja.p_promo_id IN (
    SELECT p_promo_id FROM sub1
    INTERSECT
    SELECT p_promo_id FROM sub2
)
ORDER BY ja.ws_net_paid_inc_ship DESC, ja.rn_promo
LIMIT 100
