WITH
    filtered_date AS (
        SELECT d_date_sk, d_year, d_month_seq, d_day_name
        FROM date_dim
        WHERE d_year = 2001
          AND d_month_seq BETWEEN 1 AND 12
          AND d_day_name = 'Monday'
    ),
    inv_sample AS (
        SELECT *
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        WHERE inv_quantity_on_hand > 0
    ),
    cust_returns AS (
        SELECT DISTINCT sr.sr_customer_sk
        FROM store_returns sr
    ),
    cust_web AS (
        SELECT DISTINCT wp.wp_customer_sk
        FROM web_page wp
    ),
    cust_exclusive AS (
        SELECT c.c_customer_id
        FROM cust_returns cr
        JOIN customer c ON cr.sr_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        WHERE ca.ca_city = 'Los Angeles'
        EXCEPT
        SELECT c.c_customer_id
        FROM cust_web cw
        JOIN customer c ON cw.wp_customer_sk = c.c_customer_sk
    ),
    returns_union AS (
        -- Store returns side (right outer join keeps all stores)
        SELECT
            s.s_store_id AS store_id,
            d.d_year,
            i.i_category,
            sr.sr_return_quantity AS return_qty,
            sr.sr_return_amt AS return_amt,
            sr.sr_net_loss AS net_loss
        FROM store_returns sr
        RIGHT OUTER JOIN store s
            ON sr.sr_store_sk = s.s_store_sk
        JOIN filtered_date d
            ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN item i
            ON sr.sr_item_sk = i.i_item_sk
        LEFT JOIN inv_sample inv
            ON inv.inv_item_sk = i.i_item_sk
               AND inv.inv_date_sk = d.d_date_sk
        JOIN customer_demographics cd
            ON sr.sr_cdemo_sk = cd.cd_demo_sk
        WHERE s.s_state = 'CA'
          AND i.i_brand = 'Brand#12'
          AND cd.cd_gender = 'M'
        UNION DISTINCT
        -- Catalog returns side
        SELECT
            cc.cc_name AS store_id,
            d.d_year,
            i.i_category,
            cr.cr_return_quantity AS return_qty,
            cr.cr_return_amount AS return_amt,
            cr.cr_net_loss AS net_loss
        FROM catalog_returns cr
        JOIN call_center cc
            ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN filtered_date d
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN item i
            ON cr.cr_item_sk = i.i_item_sk
        JOIN ship_mode sm
            ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN promotion p
            ON p.p_item_sk = i.i_item_sk
               AND p.p_start_date_sk = d.d_date_sk
        WHERE cc.cc_state = 'CA'
          AND sm.sm_type = 'AIR'
          AND cp.cp_type = 'A'
          AND p.p_discount_active = 'Y'
    )
SELECT
    store_id,
    d_year,
    i_category,
    SUM(return_qty) AS total_return_qty,
    SUM(return_amt) AS total_return_amt,
    AVG(return_amt) AS avg_return_amt,
    COUNT(DISTINCT store_id) AS store_count,
    (SELECT AVG(i_current_price) FROM item WHERE i_category = 'Sports') AS avg_sports_price,
    (SELECT COUNT(*) FROM cust_exclusive) AS exclusive_customer_count
FROM returns_union
GROUP BY ROLLUP (store_id, d_year, i_category)
HAVING SUM(return_amt) > 1000
ORDER BY store_id, d_year, i_category
LIMIT 100
