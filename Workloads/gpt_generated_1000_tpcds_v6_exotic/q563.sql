WITH promo_store AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        regexp_extract(p.p_promo_id, '(\\d+)', 1) AS promo_id_num,
        sum(ss.ss_net_paid) AS total_store_net_paid
    FROM promotion p
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, '[0-9]{2}')
      AND p.p_promo_id LIKE 'PROMO%'
    GROUP BY
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        regexp_extract(p.p_promo_id, '(\\d+)', 1)
),
promo_web AS (
    SELECT
        p.p_promo_sk,
        sum(ws.ws_net_paid) AS total_web_net_paid,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_country,
        w.w_city
    FROM promotion p
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_city LIKE 'San %'
    GROUP BY
        p.p_promo_sk,
        w.w_warehouse_sk,
        w.w_warehouse_id,
        w.w_country,
        w.w_city
)
SELECT
    DISTINCT concat(ps.p_promo_id, '-', pw.w_warehouse_id) AS promo_warehouse_key,
    ps.p_promo_name,
    ps.promo_id_num,
    ps.total_store_net_paid,
    pw.total_web_net_paid,
    pw.w_country,
    pw.w_city
FROM promo_store ps
JOIN promo_web pw ON pw.p_promo_sk = ps.p_promo_sk
ORDER BY ps.total_store_net_paid DESC
LIMIT 100
