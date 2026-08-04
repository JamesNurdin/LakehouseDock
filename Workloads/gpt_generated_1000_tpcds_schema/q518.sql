WITH base AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_catalog_page_sk,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        d_ret.d_year,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        CASE 
            WHEN cr.cr_return_amount > 1000 THEN 'HIGH'
            WHEN cr.cr_return_amount > 0    THEN 'LOW'
            ELSE 'ZERO'
        END AS amount_category,
        p.p_promo_name,
        wp.wp_url,
        t.total_qty_for_page
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    CROSS JOIN LATERAL (
        SELECT SUM(cr2.cr_return_quantity) AS total_qty_for_page
        FROM catalog_returns cr2
        WHERE cr2.cr_catalog_page_sk = cp.cp_catalog_page_sk
    ) t
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN date_dim d_promo ON d_ret.d_date_sk = d_promo.d_date_sk
    LEFT JOIN promotion p ON d_promo.d_date_sk = p.p_start_date_sk
    LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
                             AND wp.wp_access_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND ca.ca_state = 'CA'
      AND sm.sm_contract = 'HVDFCcQ'
),
per_page AS (
    SELECT
        cp_catalog_page_id,
        SUM(cr_return_amount) AS page_return_amt,
        COUNT(*) AS cnt,
        CASE WHEN SUM(cr_return_amount) > 5000 THEN 'BIG' ELSE 'SMALL' END AS size_category
    FROM base
    GROUP BY cp_catalog_page_id
    HAVING SUM(cr_return_amount) > 1000
),
per_customer AS (
    SELECT
        c_customer_id,
        SUM(cr_return_amount) AS cust_return_amt
    FROM base
    GROUP BY c_customer_id
    HAVING SUM(cr_return_amount) > 1000
),
intersect_ids AS (
    SELECT cp_catalog_page_id AS id FROM per_page
    INTERSECT
    SELECT c_customer_id AS id FROM per_customer
),
final AS (
    SELECT
        i.id,
        COUNT(*) OVER () AS total_ids,
        (
            SELECT MAX(page_return_amt)
            FROM per_page
            WHERE cp_catalog_page_id = i.id
        ) AS max_page_return
    FROM intersect_ids i
)
SELECT id,
       total_ids,
       max_page_return
FROM final
ORDER BY max_page_return DESC
LIMIT 100
