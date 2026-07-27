WITH sales_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        SUM(ws.ws_ext_sales_price) AS total_amount,
        'sale' AS source_type
    FROM tpcds.web_sales ws
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE s.web_manager = 'Lewis Wolf'
      AND i.i_category_id = 10
    GROUP BY i.i_category_id, i.i_category, p.p_discount_active
),
returns_agg AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        SUM(wr.wr_return_amt) AS total_amount,
        'return' AS source_type
    FROM tpcds.web_returns wr
    JOIN tpcds.item i ON wr.wr_item_sk = i.i_item_sk
    JOIN tpcds.promotion p ON i.i_item_sk = p.p_item_sk
    WHERE i.i_category_id = 10
    GROUP BY i.i_category_id, i.i_category, p.p_discount_active
)
SELECT *
FROM sales_agg
UNION ALL
SELECT *
FROM returns_agg
ORDER BY total_amount DESC
LIMIT 100
