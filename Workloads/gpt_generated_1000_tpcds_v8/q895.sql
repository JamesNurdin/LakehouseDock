WITH
-- Sample a fraction of the item table
sampled_item AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
),

-- Join web_sales with many dimension tables and web_returns
web_sales_join AS (
    SELECT
        ws.ws_order_number,
        d.d_year,
        i.i_item_id,
        i.i_color,
        c.c_customer_id AS bill_customer_id,
        ca.ca_city AS bill_city,
        cd.cd_gender,
        p.p_promo_id,
        p.p_discount_active,
        wp.wp_web_page_id,
        s.s_store_id,
        w.w_warehouse_id,
        ws.ws_net_paid,
        wr.wr_fee,
        wr.wr_return_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sold_date_sk) AS rn_ws
    FROM web_sales ws
    JOIN sampled_item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d                   ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t                   ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN customer c                  ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca         ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p                 ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp                 ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w                 ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN store s                     ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_returns wr              ON ws.ws_order_number = wr.wr_order_number
                                   AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'pink'
      AND p.p_discount_active = 'Y'
      AND ws.ws_quantity > 1
      AND ws.ws_net_paid > 100
      AND wr.wr_fee > 20
      AND wr.wr_return_tax < 30
),

-- Join catalog_returns with its dimension tables
catalog_returns_join AS (
    SELECT
        cr.cr_order_number,
        d.d_year AS return_year,
        i.i_item_id,
        i.i_color,
        c.c_customer_id AS refunded_customer_id,
        ca.ca_city AS refunded_city,
        cd.cd_gender,
        cc.cc_call_center_id,
        cp.cp_catalog_page_id,
        w.w_warehouse_id,
        cr.cr_return_amount,
        ROW_NUMBER() OVER (PARTITION BY cr.cr_order_number ORDER BY cr.cr_returned_date_sk) AS rn_cr
    FROM catalog_returns cr
    JOIN sampled_item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN date_dim d                   ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t                   ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN customer c                  ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca         ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd    ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN call_center cc              ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp              ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w                 ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.i_color = 'pink'
      AND cr.cr_return_amount > 0
      AND cc.cc_gmt_offset > -5
      AND cp.cp_type = 'type1'
),

-- Union the two streams (dedup by UNION DISTINCT)
union_all AS (
    SELECT
        ws_order_number          AS order_number,
        d_year,
        i_item_id,
        i_color,
        bill_customer_id        AS customer_id,
        bill_city                AS city,
        cd_gender                AS gender,
        p_promo_id               AS promo_id,
        p_discount_active        AS promo_active,
        wp_web_page_id           AS web_page_id,
        s_store_id               AS store_id,
        w_warehouse_id           AS warehouse_id,
        ws_net_paid              AS amount,
        rn_ws                    AS rank_in_order
    FROM web_sales_join
    UNION DISTINCT
    SELECT
        cr_order_number          AS order_number,
        return_year              AS d_year,
        i_item_id,
        i_color,
        refunded_customer_id    AS customer_id,
        refunded_city            AS city,
        cd_gender                AS gender,
        CAST(NULL AS varchar)   AS promo_id,
        CAST(NULL AS varchar)   AS promo_active,
        CAST(NULL AS varchar)   AS web_page_id,
        CAST(NULL AS varchar)   AS store_id,
        w_warehouse_id,
        cr_return_amount         AS amount,
        rn_cr                    AS rank_in_order
    FROM catalog_returns_join
),

-- Distinct order numbers from web_sales and catalog_returns
order_numbers_ws AS (
    SELECT DISTINCT ws_order_number AS order_number
    FROM web_sales
),
order_numbers_cr AS (
    SELECT DISTINCT cr_order_number AS order_number
    FROM catalog_returns
),

-- Order numbers that appear in web_sales but NOT in catalog_returns
order_numbers_excluded AS (
    SELECT order_number
    FROM order_numbers_ws
    EXCEPT
    SELECT order_number
    FROM order_numbers_cr
),

-- Order numbers that appear in BOTH tables
order_numbers_common AS (
    SELECT order_number
    FROM order_numbers_ws
    INTERSECT
    SELECT order_number
    FROM order_numbers_cr
),

-- Final filtering, ranking and a semi‑join via EXISTS
final_filtered AS (
    SELECT
        u.*,
        DENSE_RANK() OVER (PARTITION BY u.order_number ORDER BY u.amount DESC) AS amount_rank,
        CASE WHEN EXISTS (
                SELECT 1
                FROM promotion p
                WHERE p.p_promo_id = u.promo_id
                  AND p.p_discount_active = 'Y'
            ) THEN 1 ELSE 0 END AS has_active_promo
    FROM union_all u
    WHERE (
            u.order_number IN (SELECT order_number FROM order_numbers_excluded)
            OR u.order_number IN (SELECT order_number FROM order_numbers_common)
          )
      AND u.amount IS NOT NULL
)
SELECT
    ff.order_number,
    ff.d_year,
    ff.i_item_id,
    ff.i_color,
    ff.customer_id,
    ff.city,
    ff.gender,
    ff.promo_id,
    ff.promo_active,
    ff.web_page_id,
    ff.store_id,
    ff.warehouse_id,
    ff.amount,
    ff.amount_rank,
    ff.has_active_promo
FROM final_filtered ff
ORDER BY ff.amount DESC, ff.amount_rank
LIMIT 100
