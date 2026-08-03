WITH cc_join AS (
    SELECT
        d.d_year,
        d.d_date,
        cc.cc_name,
        d.d_date_sk AS date_sk
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
),
ws_join AS (
    SELECT
        d.d_year,
        d.d_date,
        ws.web_name,
        d.d_date_sk AS date_sk
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
),
full_info AS (
    SELECT
        COALESCE(cc.d_year, ws.d_year) AS d_year,
        COALESCE(cc.d_date, ws.d_date) AS d_date,
        COALESCE(cc.cc_name, 'UNKNOWN_CC') AS cc_name,
        COALESCE(ws.web_name, 'UNKNOWN_WS') AS web_name
    FROM cc_join cc
    FULL OUTER JOIN ws_join ws ON cc.date_sk = ws.date_sk
),
agg1 AS (
    SELECT
        fi.d_year,
        i.i_category,
        fi.cc_name,
        fi.web_name,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_returns,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn,
        MIN(d.d_date) AS first_sale_date,
        MAX(d.d_date) AS last_sale_date,
        (SELECT AVG(ss2.ss_ext_sales_price) FROM store_sales ss2) AS overall_avg_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        AND d.d_date_sk = inv.inv_date_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        AND (wp.wp_creation_date_sk = d.d_date_sk OR wp.wp_access_date_sk = d.d_date_sk)
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN full_info fi ON fi.d_year = d.d_year
    WHERE d.d_year = 2001
      AND ca.ca_city = 'Oakdale'
      AND i.i_color = 'Red'
      AND p.p_discount_active = 'Y'
    GROUP BY fi.d_year, i.i_category, fi.cc_name, fi.web_name, fi.d_date
),
ranked_agg AS (
    SELECT
        d_year,
        i_category,
        cc_name,
        web_name,
        total_sales,
        total_returns,
        avg_inventory,
        sales_txn,
        overall_avg_sales,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_rank
    FROM agg1
)
SELECT
    d_year,
    i_category,
    cc_name,
    web_name,
    total_sales,
    total_returns,
    avg_inventory,
    sales_txn,
    overall_avg_sales,
    category_rank
FROM ranked_agg
WHERE category_rank = 1
UNION DISTINCT
SELECT
    d_year,
    i_category,
    cc_name,
    web_name,
    total_sales,
    total_returns,
    avg_inventory,
    sales_txn,
    overall_avg_sales,
    category_rank
FROM ranked_agg
WHERE total_sales > 100000
ORDER BY total_sales DESC
LIMIT 100
