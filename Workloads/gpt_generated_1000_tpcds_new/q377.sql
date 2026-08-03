WITH sampled_item AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    u.i_item_id,
    u.cp_catalog_number,
    u.r_reason_desc,
    u.total_net_paid,
    u.orders_cnt,
    u.total_promo_cost
FROM (
    /* ---------- First branch of UNION ---------- */
    SELECT
        i_samp.i_item_id,
        cp.cp_catalog_number,
        r.r_reason_desc,
        SUM(ws.ws_net_paid_inc_tax)                AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number)          AS orders_cnt,
        SUM(p.p_cost)                               AS total_promo_cost
    FROM sampled_item AS i_samp
    JOIN inventory AS inv1      ON inv1.inv_item_sk = i_samp.i_item_sk
    JOIN item      AS i2        ON i2.i_item_sk = inv1.inv_item_sk
    JOIN catalog_returns AS cr ON cr.cr_item_sk = i_samp.i_item_sk
    JOIN catalog_page   AS cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN reason         AS r  ON r.r_reason_sk = cr.cr_reason_sk
    JOIN web_sales      AS ws ON ws.ws_item_sk = i2.i_item_sk
    JOIN promotion      AS p  ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item      AS i3        ON p.p_item_sk = i3.i_item_sk
    JOIN inventory AS inv2      ON inv2.inv_item_sk = i3.i_item_sk
    WHERE i_samp.i_category_id = 5
    GROUP BY i_samp.i_item_id, cp.cp_catalog_number, r.r_reason_desc

    UNION

    /* ---------- Second branch of UNION (uses FULL OUTER JOIN) ---------- */
    SELECT
        i_samp.i_item_id,
        cp.cp_catalog_number,
        r.r_reason_desc,
        SUM(ws.ws_net_paid_inc_tax)                AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number)          AS orders_cnt,
        SUM(p.p_cost)                               AS total_promo_cost
    FROM sampled_item AS i_samp
    FULL OUTER JOIN catalog_returns AS cr ON cr.cr_item_sk = i_samp.i_item_sk
    FULL OUTER JOIN reason         AS r  ON r.r_reason_sk = cr.cr_reason_sk
    FULL OUTER JOIN catalog_page   AS cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    JOIN inventory AS inv1      ON inv1.inv_item_sk = i_samp.i_item_sk
    JOIN web_sales  AS ws      ON ws.ws_item_sk = i_samp.i_item_sk
    JOIN promotion  AS p       ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i_samp.i_wholesale_cost > 5
    GROUP BY i_samp.i_item_id, cp.cp_catalog_number, r.r_reason_desc
) AS u
INTERSECT
SELECT
    i_samp.i_item_id,
    cp.cp_catalog_number,
    r.r_reason_desc,
    SUM(ws.ws_net_paid_inc_tax)                AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number)          AS orders_cnt,
    SUM(p.p_cost)                               AS total_promo_cost
FROM sampled_item AS i_samp
JOIN inventory          AS inv1 ON inv1.inv_item_sk = i_samp.i_item_sk
JOIN catalog_returns    AS cr   ON cr.cr_item_sk = i_samp.i_item_sk
JOIN catalog_page       AS cp   ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN reason             AS r    ON r.r_reason_sk = cr.cr_reason_sk
JOIN web_sales          AS ws   ON ws.ws_item_sk = i_samp.i_item_sk
JOIN promotion          AS p    ON ws.ws_promo_sk = p.p_promo_sk
GROUP BY i_samp.i_item_id, cp.cp_catalog_number, r.r_reason_desc
LIMIT 100
