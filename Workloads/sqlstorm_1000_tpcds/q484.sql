WITH unified_sales AS (
    SELECT 'store' AS src,
           ss.ss_sold_date_sk AS sold_date_sk,
           ss.ss_store_sk AS location_sk,
           st.s_store_id AS location_id,
           ss.ss_item_sk AS item_sk,
           i.i_category AS category,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           ss.ss_quantity AS quantity,
           ss.ss_ext_discount_amt AS discount_amt,
           ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL
    SELECT 'catalog' AS src,
           cs.cs_sold_date_sk,
           cs.cs_call_center_sk,
           cc.cc_call_center_id,
           cs.cs_item_sk,
           i.i_category,
           cs.cs_net_paid,
           cs.cs_net_profit,
           cs.cs_quantity,
           cs.cs_ext_discount_amt,
           cs.cs_promo_sk
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk

    UNION ALL
    SELECT 'web' AS src,
           ws.ws_sold_date_sk,
           ws.ws_web_page_sk,
           wp.wp_web_page_id,
           ws.ws_item_sk,
           i.i_category,
           ws.ws_net_paid,
           ws.ws_net_profit,
           ws.ws_quantity,
           ws.ws_ext_discount_amt,
           ws.ws_promo_sk
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
unified_returns AS (
    SELECT 'store' AS src,
           sr.sr_returned_date_sk AS returned_date_sk,
           sr.sr_store_sk AS location_sk,
           st.s_store_id AS location_id,
           sr.sr_item_sk AS item_sk,
           i.i_category AS category,
           sr.sr_net_loss AS net_loss,
           sr.sr_return_quantity AS quantity
    FROM store_returns sr
    JOIN store st ON sr.sr_store_sk = st.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk

    UNION ALL
    SELECT 'catalog' AS src,
           cr.cr_returned_date_sk,
           cr.cr_call_center_sk,
           cc.cc_call_center_id,
           cr.cr_item_sk,
           i.i_category,
           cr.cr_net_loss,
           cr.cr_return_quantity
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk

    UNION ALL
    SELECT 'web' AS src,
           wr.wr_returned_date_sk,
           wr.wr_web_page_sk,
           wp.wp_web_page_id,
           wr.wr_item_sk,
           i.i_category,
           wr.wr_net_loss,
           wr.wr_return_quantity
    FROM web_returns wr
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
sales_agg AS (
    SELECT
        d.d_year,
        src,
        location_id,
        category,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(quantity) AS total_quantity,
        SUM(discount_amt) AS total_discount,
        SUM(promo_cost) AS total_promo_cost
    FROM (
        SELECT u.*, p.p_cost AS promo_cost
        FROM unified_sales u
        LEFT JOIN promotion p ON u.promo_sk = p.p_promo_sk
    ) us
    JOIN date_dim d ON us.sold_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS (
        (d.d_year, src, location_id, category),
        (d.d_year, src, location_id),
        (d.d_year, src, category),
        (d.d_year, src),
        (d.d_year)
    )
),
returns_agg AS (
    SELECT
        d.d_year,
        src,
        location_id,
        category,
        SUM(net_loss) AS total_net_loss,
        SUM(quantity) AS total_return_qty
    FROM unified_returns ur
    JOIN date_dim d ON ur.returned_date_sk = d.d_date_sk
    GROUP BY GROUPING SETS (
        (d.d_year, src, location_id, category),
        (d.d_year, src, location_id),
        (d.d_year, src, category),
        (d.d_year, src),
        (d.d_year)
    )
),
combined AS (
    SELECT
        COALESCE(sa.d_year, ra.d_year) AS d_year,
        COALESCE(sa.src, ra.src) AS src,
        COALESCE(sa.location_id, ra.location_id, 'ALL') AS location_id,
        COALESCE(sa.category, ra.category, 'ALL') AS category,
        COALESCE(sa.total_net_paid, 0) AS total_net_paid,
        COALESCE(sa.total_net_profit, 0) AS total_net_profit,
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(sa.total_discount, 0) AS total_discount,
        COALESCE(sa.total_promo_cost, 0) AS total_promo_cost,
        COALESCE(ra.total_net_loss, 0) AS total_net_loss,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty,
        (COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0)) AS net_margin,
        CASE WHEN COALESCE(sa.total_quantity, 0) > 0
             THEN COALESCE(sa.total_discount, 0) / COALESCE(sa.total_quantity, 1)
        END AS avg_discount_per_unit,
        CASE WHEN COALESCE(sa.total_net_paid, 0) > 0
             THEN (COALESCE(sa.total_discount, 0) + COALESCE(sa.total_promo_cost, 0)) / COALESCE(sa.total_net_paid, 1)
        END AS discount_to_sales_ratio
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.d_year = ra.d_year
        AND sa.src = ra.src
        AND sa.location_id IS NOT DISTINCT FROM ra.location_id
        AND sa.category IS NOT DISTINCT FROM ra.category
)
SELECT
    d_year,
    src,
    location_id,
    category,
    total_net_paid,
    total_net_profit,
    total_net_loss,
    net_margin,
    avg_discount_per_unit,
    discount_to_sales_ratio,
    ROW_NUMBER() OVER (PARTITION BY d_year, src ORDER BY net_margin DESC) AS rank_by_margin
FROM combined
WHERE net_margin > 0
ORDER BY d_year, src, rank_by_margin
LIMIT 200
