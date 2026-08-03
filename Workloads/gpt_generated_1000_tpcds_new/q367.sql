/*
Goal: Identify customers in the year 2001 who both purchased items online (web_sales) and had catalog returns, summarizing their sales, returns, and return counts, and only keeping customers present in both datasets. The query joins all selected tables, applies realistic filter predicates, uses a FULL OUTER JOIN, includes a scalar subquery, intersects key sets, groups and aggregates, orders the result and pages it.
*/
WITH web_data AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(ws.ws_net_paid) AS total_sales,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
        (SELECT COUNT(*) FROM web_page wp_sub WHERE wp_sub.wp_type = 'home') AS total_home_pages
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    FULL OUTER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                              AND wr.wr_item_sk = ws.ws_item_sk
    WHERE d.d_year = 2001
      AND ib.ib_lower_bound >= 30000
      AND hd.hd_vehicle_count >= 2
    GROUP BY c.c_customer_id, d.d_year
),

catalog_data AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_cat_returns,
        COUNT(cr.cr_return_quantity) AS cat_return_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND cp.cp_catalog_number IN (5, 14, 18)
      AND ib.ib_upper_bound <= 80000
    GROUP BY c.c_customer_id, d.d_year
),

common_keys AS (
    SELECT c_customer_id, d_year FROM web_data
    INTERSECT
    SELECT c_customer_id, d_year FROM catalog_data
)
SELECT
    wd.c_customer_id,
    wd.d_year,
    wd.total_sales,
    wd.total_returns,
    wd.orders_cnt,
    wd.total_home_pages,
    cd.total_cat_returns,
    cd.cat_return_cnt
FROM web_data wd
JOIN common_keys ck ON wd.c_customer_id = ck.c_customer_id AND wd.d_year = ck.d_year
LEFT JOIN catalog_data cd ON cd.c_customer_id = wd.c_customer_id AND cd.d_year = wd.d_year
ORDER BY wd.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
