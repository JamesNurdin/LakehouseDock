/*
Goal: Identify the highest‑revenue web pages per web site, showing their URL, site details, sales totals, a coupon‑level flag, and ranking by revenue and quantity. The query filters on coupon amount, net paid amount, page image count, page end date, and site attributes, uses a subquery with DISTINCT, applies CASE logic, window ranking, and limits to the top 100 rows.
*/
WITH page_sales AS (
    SELECT
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
        MAX(ws.ws_coupon_amt) AS max_coupon
    FROM tpcds.web_sales ws
    WHERE ws.ws_coupon_amt > 500                               -- predicate 1
      AND ws.ws_net_paid_inc_ship_tax BETWEEN 1000 AND 6000   -- predicate 2
    GROUP BY ws.ws_web_page_sk, ws.ws_web_site_sk
),
page_details AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_image_count,
        wp.wp_rec_end_date
    FROM tpcds.web_page wp
    WHERE wp.wp_image_count >= 2                               -- predicate 3
      AND wp.wp_rec_end_date >= DATE '2000-01-01'               -- predicate 4
),
site_details AS (
    SELECT
        s.web_site_sk,
        s.web_name,
        s.web_city,
        s.web_state,
        s.web_company_id,
        s.web_rec_end_date
    FROM tpcds.web_site s
    WHERE s.web_state IN ('CA', 'NY', 'TX')
      AND s.web_company_id <> 1
)
SELECT
    ws_total.ws_web_page_sk,
    pd.wp_url,
    sd.web_name,
    sd.web_city,
    sd.web_state,
    ws_total.total_net_paid,
    ws_total.total_quantity,
    ws_total.distinct_orders,
    CASE
        WHEN ws_total.max_coupon > 1000 THEN 'HIGH'
        WHEN ws_total.max_coupon > 500  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS coupon_level,
    RANK() OVER (PARTITION BY sd.web_site_sk ORDER BY ws_total.total_net_paid DESC) AS revenue_rank,
    ROW_NUMBER() OVER (PARTITION BY sd.web_site_sk ORDER BY ws_total.total_quantity DESC) AS quantity_rownum
FROM page_sales ws_total
JOIN page_details pd
    ON ws_total.ws_web_page_sk = pd.wp_web_page_sk
JOIN site_details sd
    ON ws_total.ws_web_site_sk = sd.web_site_sk
WHERE EXISTS (
    SELECT 1
    FROM (
        SELECT DISTINCT wp2.wp_web_page_sk
        FROM tpcds.web_page wp2
        WHERE wp2.wp_image_count > 5
    ) img_pages
    WHERE img_pages.wp_web_page_sk = pd.wp_web_page_sk
)
ORDER BY sd.web_state, revenue_rank
LIMIT 100
