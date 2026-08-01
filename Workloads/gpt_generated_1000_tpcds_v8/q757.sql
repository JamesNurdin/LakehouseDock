-- Goal: Get a multi‑dimensional view of net revenue across store, catalog and web channels, flag high‑revenue rows, and analyse return losses.
-- The query joins all 15 TPC‑DS tables using only the permitted join keys,
-- applies several filters, samples store sales, intersects catalog and web order numbers,
-- uses a full outer join, left outer joins to returns, aggregates with GROUPING SETS and a CASE expression.
WITH
-- Sample a fraction of store sales and keep only the columns needed for later joins
store_sales_sample AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_net_paid,
        ss.ss_store_sk,
        ss.ss_sold_time_sk,
        ss.ss_customer_sk,
        ss.ss_addr_sk,
        ss.ss_hdemo_sk
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (5)   -- 5% random sample
),

-- Join the sampled store sales to its dimension tables and apply filters
store_joined AS (
    SELECT
        ss.ss_item_sk               AS item_sk,
        ss.ss_net_paid              AS store_net_paid,
        s.s_store_name,
        c.c_customer_id,
        ca.ca_city,
        hd.hd_income_band_sk,
        t.t_hour
    FROM store_sales_sample ss
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t            ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'                     -- predicate 1
      AND ca.ca_street_type = 'Avenue'         -- predicate 2
      AND hd.hd_income_band_sk BETWEEN 5 AND 15   -- predicate 3
      AND t.t_hour BETWEEN 8 AND 18            -- predicate 4
),

-- Join catalog sales to its dimension tables and filter
catalog_joined AS (
    SELECT
        cs.cs_order_number          AS order_number,
        cs.cs_item_sk               AS item_sk,
        cs.cs_net_paid              AS catalog_net_paid,
        cc.cc_name,
        cp.cp_type                  AS catalog_page_type,
        sm.sm_type                  AS ship_mode_type,
        t.t_hour,
        hd.hd_dep_count,
        ca.ca_state
    FROM catalog_sales cs
    JOIN call_center cc          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp          ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm            ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t              ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_address ca     ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cc.cc_country = 'United States'   -- predicate 5
      AND cp.cp_department = 'Books'        -- predicate 6
      AND sm.sm_carrier = 'UPS'             -- predicate 7
      AND t.t_minute < 30                  -- predicate 8
),

-- Join web sales to its dimension tables and filter
web_joined AS (
    SELECT
        ws.ws_order_number          AS order_number,
        ws.ws_item_sk               AS item_sk,
        ws.ws_net_paid              AS web_net_paid,
        ws.ws_net_profit,
        ws.ws_quantity,
        wp.wp_type                  AS web_page_type,
        we.web_name,
        sm.sm_type                  AS ship_mode_type,
        t.t_hour,
        hd.hd_vehicle_count,
        ca.ca_zip
    FROM web_sales ws
    JOIN web_page wp            ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we            ON ws.ws_web_site_sk = we.web_site_sk
    JOIN ship_mode sm           ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t             ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer_address ca    ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE we.web_state = 'TX'                -- predicate 9
      AND wp.wp_type = 'Content'             -- predicate 10
),

-- Intersect the order numbers that appear both in catalog and web sales
intersect_orders AS (
    SELECT order_number FROM catalog_joined
    INTERSECT
    SELECT order_number FROM web_joined
),

-- Full outer join the intersected order numbers with the three sales domains
full_outer AS (
    SELECT
        io.order_number,
        sw.store_net_paid,
        cj.catalog_net_paid,
        wj.web_net_paid,
        cj.ship_mode_type AS catalog_ship_mode,
        wj.ship_mode_type AS web_ship_mode,
        cj.catalog_page_type,
        wj.web_page_type,
        sw.item_sk          AS store_item_sk,
        cj.item_sk          AS catalog_item_sk,
        wj.item_sk          AS web_item_sk
    FROM intersect_orders io
    FULL OUTER JOIN store_joined sw   ON io.order_number = sw.item_sk
    FULL OUTER JOIN catalog_joined cj ON io.order_number = cj.order_number
    FULL OUTER JOIN web_joined wj     ON io.order_number = wj.order_number
),

-- Bring in return information with LEFT OUTER JOINs (keep rows even when no returns exist)
left_with_returns AS (
    SELECT
        fo.*,
        cr.cr_net_loss AS catalog_return_loss,
        wr.wr_net_loss AS web_return_loss
    FROM full_outer fo
    LEFT OUTER JOIN catalog_returns cr ON fo.order_number = cr.cr_order_number
    LEFT OUTER JOIN web_returns wr    ON fo.order_number = wr.wr_order_number
),

-- First level aggregation, including a CASE expression
final_agg AS (
    SELECT
        COALESCE(store_net_paid, 0) +
        COALESCE(catalog_net_paid, 0) +
        COALESCE(web_net_paid, 0)                     AS total_net_paid,
        CASE
            WHEN COALESCE(store_net_paid, 0) +
                 COALESCE(catalog_net_paid, 0) +
                 COALESCE(web_net_paid, 0) > 5000 THEN 'HIGH'
            ELSE 'LOW'
        END                                          AS revenue_band,
        COALESCE(catalog_ship_mode, web_ship_mode)   AS ship_mode_type,
        COALESCE(catalog_page_type, web_page_type)  AS page_type,
        catalog_return_loss,
        web_return_loss
    FROM left_with_returns
)

SELECT
    revenue_band,
    ship_mode_type,
    page_type,
    SUM(total_net_paid)                       AS sum_total_net_paid,
    AVG(catalog_return_loss)                  AS avg_catalog_return_loss,
    AVG(web_return_loss)                      AS avg_web_return_loss
FROM final_agg
GROUP BY GROUPING SETS (
    (revenue_band, ship_mode_type, page_type),
    (revenue_band, ship_mode_type),
    (revenue_band),
    ()
)
HAVING SUM(total_net_paid) > 10000
ORDER BY sum_total_net_paid DESC
LIMIT 100
