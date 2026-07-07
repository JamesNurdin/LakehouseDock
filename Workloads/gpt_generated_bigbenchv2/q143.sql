WITH store_agg AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        i.i_category AS category,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_customer_id, i.i_category
),
web_agg AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        i.i_category AS category,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_customer_id, i.i_category
),
combined AS (
    SELECT
        COALESCE(sa.customer_id, wa.customer_id) AS customer_id,
        COALESCE(sa.category, wa.category) AS category,
        COALESCE(sa.store_qty, 0) + COALESCE(wa.web_qty, 0) AS total_qty,
        COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa
        ON sa.customer_id = wa.customer_id
        AND sa.category = wa.category
),
customer_totals AS (
    SELECT
        combined.customer_id,
        SUM(combined.total_revenue) AS overall_revenue
    FROM combined
    GROUP BY combined.customer_id
),
ranked_customers AS (
    SELECT
        ct.customer_id,
        ct.overall_revenue,
        ROW_NUMBER() OVER (ORDER BY ct.overall_revenue DESC) AS rn
    FROM customer_totals ct
)
SELECT
    c.c_customer_id,
    c.c_name,
    combined.category,
    combined.total_qty,
    combined.total_revenue,
    rc.overall_revenue
FROM combined
JOIN ranked_customers rc ON combined.customer_id = rc.customer_id
JOIN customers c ON c.c_customer_id = rc.customer_id
WHERE rc.rn <= 10
ORDER BY rc.overall_revenue DESC, combined.category
