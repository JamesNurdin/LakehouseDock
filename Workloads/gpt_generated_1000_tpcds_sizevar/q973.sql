/* goal: Identify warehouses (with city starting with "A") that have inventory, recent sales driven by discounts, or returns due to color‑related reasons. The query shows inventory level, discounted sales metrics, return metrics, a derived location description, and a global row number for ordering. */
WITH wh_inv AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        i.inv_quantity_on_hand,
        ROW_NUMBER() OVER (ORDER BY w.w_warehouse_name) AS wh_rownum
    FROM
        warehouse w
        FULL OUTER JOIN inventory i
            ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        w.w_city LIKE 'A%'
),
cat_sales_agg AS (
    SELECT
        w.w_warehouse_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(cs.cs_net_paid) DESC) AS sales_rank,
        regexp_extract(p.p_promo_name, '(\\w+)', 1) AS promo_type
    FROM
        catalog_sales cs
        JOIN warehouse w
            ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        regexp_like(p.p_promo_name, '(?i)discount')
    GROUP BY
        w.w_warehouse_name,
        p.p_promo_name
),
returns_agg AS (
    SELECT
        w.w_warehouse_name,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_name ORDER BY SUM(cr.cr_net_loss) DESC) AS loss_rank
    FROM
        catalog_returns cr
        JOIN warehouse w
            ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        regexp_like(r.r_reason_desc, 'color')
    GROUP BY
        w.w_warehouse_name
)
SELECT
    concat(wh.w_city, '-', wh.w_warehouse_name) AS location_desc,
    wh.inv_quantity_on_hand,
    cs.total_net_paid,
    cs.orders,
    cs.sales_rank,
    NULL AS total_net_loss,
    NULL AS return_cnt,
    NULL AS loss_rank,
    cs.promo_type,
    wh.wh_rownum
FROM
    wh_inv wh
    LEFT JOIN cat_sales_agg cs
        ON wh.w_warehouse_name = cs.w_warehouse_name

UNION DISTINCT

SELECT
    concat(wh.w_city, '-', wh.w_warehouse_name) AS location_desc,
    wh.inv_quantity_on_hand,
    NULL AS total_net_paid,
    NULL AS orders,
    NULL AS sales_rank,
    r.total_net_loss,
    r.return_cnt,
    r.loss_rank,
    NULL AS promo_type,
    wh.wh_rownum
FROM
    wh_inv wh
    LEFT JOIN returns_agg r
        ON wh.w_warehouse_name = r.w_warehouse_name

ORDER BY
    location_desc
LIMIT 100
