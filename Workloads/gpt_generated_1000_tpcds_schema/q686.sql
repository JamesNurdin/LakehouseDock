/*
Goal: Summarize profit and sales metrics per promotion and year, combining store and catalog sales, filtering to items sold in both channels, categorizing profit/price, and enriching with web site info while demonstrating set operations, cross joins, and correlated aggregates.
*/
WITH
    intersect_items AS (
        SELECT ss_item_sk FROM store_sales
        INTERSECT
        SELECT cs_item_sk FROM catalog_sales
    ),
    except_items AS (
        SELECT ss_item_sk FROM store_sales
        EXCEPT
        SELECT cs_item_sk FROM catalog_sales
    ),
    base_store AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_sold_time_sk,
            ss.ss_item_sk,
            ss.ss_net_profit,
            ss.ss_net_paid_inc_tax,
            d.d_year,
            p.p_promo_sk,
            p.p_promo_name,
            CASE WHEN ss.ss_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
            c.c_customer_id,
            cd.cd_gender,
            hd.hd_income_band_sk,
            t.t_hour
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        WHERE ss.ss_item_sk IN (SELECT cs_item_sk FROM catalog_sales)
    ),
    base_catalog AS (
        SELECT
            cs.cs_sold_date_sk,
            cs.cs_sold_time_sk,
            cs.cs_item_sk,
            cs.cs_ext_sales_price,
            d.d_year,
            p.p_promo_sk,
            p.p_promo_name,
            CASE WHEN cs.cs_ext_sales_price > 1000 THEN 'HIGH' ELSE 'LOW' END AS price_category,
            cc.cc_call_center_id,
            cp.cp_catalog_page_id,
            t.t_hour
        FROM catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    ),
    union_all AS (
        SELECT
            p_promo_sk,
            d_year,
            ss_net_profit AS metric,
            profit_flag AS category
        FROM base_store
        UNION
        SELECT
            p_promo_sk,
            d_year,
            cs_ext_sales_price AS metric,
            price_category AS category
        FROM base_catalog
    ),
    cross_set AS (
        SELECT d.d_year, v.val
        FROM (SELECT DISTINCT d_year FROM date_dim WHERE d_year BETWEEN 1998 AND 2000) d
        CROSS JOIN (VALUES (1), (2), (3)) AS v(val)
    ),
    web_site_used AS (
        SELECT ws.web_site_id, ws.web_name, open_d.d_year AS open_year, close_d.d_year AS close_year
        FROM web_site ws
        JOIN date_dim open_d ON ws.web_open_date_sk = open_d.d_date_sk
        JOIN date_dim close_d ON ws.web_close_date_sk = close_d.d_date_sk
        WHERE open_d.d_year = 1999
    ),
    intersect_cnt AS (
        SELECT COUNT(*) AS cnt_intersect FROM intersect_items
    ),
    except_cnt AS (
        SELECT COUNT(*) AS cnt_except FROM except_items
    )
SELECT
    u.p_promo_sk,
    p.p_promo_name,
    u.d_year,
    SUM(u.metric) AS total_metric,
    COUNT(*) AS rows_cnt,
    MAX(u.category) AS any_category,
    (SELECT SUM(ss2.ss_net_profit)
       FROM store_sales ss2
       WHERE ss2.ss_promo_sk = u.p_promo_sk) AS total_store_profit_per_promo,
    ic.cnt_intersect,
    ec.cnt_except,
    ws.web_site_id,
    ws.web_name
FROM union_all u
JOIN promotion p ON u.p_promo_sk = p.p_promo_sk
JOIN cross_set cs ON u.d_year = cs.d_year
CROSS JOIN web_site_used ws
JOIN intersect_cnt ic ON TRUE
JOIN except_cnt ec ON TRUE
GROUP BY
    u.p_promo_sk,
    p.p_promo_name,
    u.d_year,
    ws.web_site_id,
    ws.web_name,
    ic.cnt_intersect,
    ec.cnt_except
ORDER BY total_metric DESC
LIMIT 100
