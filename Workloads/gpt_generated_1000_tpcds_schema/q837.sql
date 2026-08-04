WITH sampled_store_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        d.d_date,
        i.i_item_id,
        s.s_store_name,
        ss.ss_net_paid,
        ss.ss_item_sk
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
),
intersect_orders AS (
    SELECT cs.cs_order_number AS order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    INTERSECT
    SELECT ss.ss_ticket_number AS order_number
    FROM store_sales ss
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
SELECT
    store_name,
    item_id,
    d_date,
    net_paid,
    promo_name,
    ROW_NUMBER() OVER (ORDER BY d_date) AS rn
FROM (
    SELECT
        sss.s_store_name AS store_name,
        sss.i_item_id AS item_id,
        sss.d_date,
        sss.ss_net_paid AS net_paid,
        promo.p_promo_name AS promo_name
    FROM sampled_store_sales sss
    CROSS JOIN LATERAL (
        SELECT p.p_promo_name
        FROM promotion p
        WHERE p.p_item_sk = sss.ss_item_sk
        ORDER BY p.p_start_date_sk DESC
        LIMIT 1
    ) AS promo

    UNION

    SELECT
        'Catalog Returns' AS store_name,
        CAST(cr.cr_item_sk AS varchar) AS item_id,
        d_ret.d_date,
        cr.cr_return_amount AS net_paid,
        r.r_reason_desc AS promo_name
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_item_sk IN (SELECT order_number FROM intersect_orders)
) AS combined
ORDER BY rn
LIMIT 100
