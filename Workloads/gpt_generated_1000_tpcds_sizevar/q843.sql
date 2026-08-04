WITH
    sr AS (
        SELECT sr.sr_store_sk,
               sr.sr_returned_date_sk,
               sr.sr_item_sk,
               sr.sr_reason_sk,
               sr.sr_return_amt,
               sr.sr_customer_sk,
               sr.sr_cdemo_sk,
               sr.sr_addr_sk
        FROM store_returns sr
    ),
    cr AS (
        SELECT cr.cr_returned_date_sk,
               cr.cr_item_sk,
               cr.cr_return_amount,
               cr.cr_refunded_customer_sk,
               cr.cr_refunded_cdemo_sk,
               cr.cr_refunded_addr_sk,
               cr.cr_call_center_sk,
               cr.cr_reason_sk
        FROM catalog_returns cr
    ),
    wr AS (
        SELECT wr.wr_returned_date_sk,
               wr.wr_item_sk,
               wr.wr_return_amt,
               wr.wr_refunded_customer_sk,
               wr.wr_refunded_cdemo_sk,
               wr.wr_refunded_addr_sk,
               wr.wr_web_page_sk,
               wr.wr_reason_sk
        FROM web_returns wr
    ),
    d_date AS (
        SELECT d_date_sk,
               d_year,
               d_date
        FROM date_dim
    ),
    itm AS (
        SELECT i_item_sk,
               i_brand,
               i_category,
               i_product_name,
               i_current_price
        FROM item
    ),
    cust AS (
        SELECT c_customer_sk,
               c_customer_id,
               c_birth_year
        FROM customer
    ),
    addr AS (
        SELECT ca_address_sk,
               ca_city,
               ca_state
        FROM customer_address
    ),
    demo AS (
        SELECT cd_demo_sk,
               cd_gender,
               cd_education_status
        FROM customer_demographics
    ),
    reason_tbl AS (
        SELECT r_reason_sk,
               r_reason_desc
        FROM reason
    ),
    store_tbl AS (
        SELECT s_store_sk,
               s_store_name,
               s_geography_class,
               s_closed_date_sk
        FROM store
    ),
    call_ctr AS (
        SELECT cc_call_center_sk,
               cc_name
        FROM call_center
    ),
    web_pg AS (
        SELECT wp_web_page_sk,
               wp_url,
               wp_type
        FROM web_page
    ),
    promo AS (
        SELECT p_promo_sk,
               p_promo_id,
               p_item_sk,
               p_discount_active
        FROM promotion
    ),
    joined AS (
        SELECT
            sr.sr_store_sk,
            sr.sr_returned_date_sk,
            sr.sr_item_sk,
            sr.sr_reason_sk,
            sr.sr_return_amt,
            cr.cr_return_amount,
            wr.wr_return_amt,
            d_date.d_year,
            itm.i_brand,
            itm.i_category,
            cust.c_customer_id,
            addr.ca_city,
            demo.cd_gender,
            reason_tbl.r_reason_desc,
            store_tbl.s_store_name,
            call_ctr.cc_name                     AS call_center_name,
            web_pg.wp_url,
            promo.p_promo_id,
            promo.p_discount_active,
            d_close.d_year                        AS store_closed_year
        FROM sr
        JOIN store_tbl ON sr.sr_store_sk = store_tbl.s_store_sk
        JOIN d_date ON sr.sr_returned_date_sk = d_date.d_date_sk
        JOIN itm ON sr.sr_item_sk = itm.i_item_sk
        JOIN reason_tbl ON sr.sr_reason_sk = reason_tbl.r_reason_sk
        JOIN cust ON sr.sr_customer_sk = cust.c_customer_sk
        JOIN addr ON sr.sr_addr_sk = addr.ca_address_sk
        JOIN demo ON sr.sr_cdemo_sk = demo.cd_demo_sk
        LEFT JOIN cr ON cr.cr_item_sk = itm.i_item_sk
                    AND cr.cr_returned_date_sk = d_date.d_date_sk
        LEFT JOIN call_ctr ON cr.cr_call_center_sk = call_ctr.cc_call_center_sk
        LEFT JOIN wr ON wr.wr_item_sk = itm.i_item_sk
                    AND wr.wr_returned_date_sk = d_date.d_date_sk
        LEFT JOIN web_pg ON wr.wr_web_page_sk = web_pg.wp_web_page_sk
        LEFT JOIN promo ON promo.p_item_sk = itm.i_item_sk
        LEFT JOIN date_dim d_close ON store_tbl.s_closed_date_sk = d_close.d_date_sk
    ),
    agg AS (
        SELECT
            joined.s_store_name,
            joined.d_year,
            SUM(joined.sr_return_amt)                              AS total_store_return,
            SUM(COALESCE(joined.cr_return_amount, 0))               AS total_catalog_return,
            SUM(COALESCE(joined.wr_return_amt, 0))                  AS total_web_return,
            COUNT(DISTINCT joined.c_customer_id)                    AS distinct_customers,
            CASE WHEN SUM(joined.sr_return_amt) > 20000 THEN 'HIGH' ELSE 'LOW' END AS return_level,
            LAG(SUM(joined.sr_return_amt)) OVER (PARTITION BY joined.s_store_name ORDER BY joined.d_year) AS lag_store_return,
            ROW_NUMBER() OVER (PARTITION BY joined.s_store_name ORDER BY SUM(joined.sr_return_amt) DESC) AS rn
        FROM joined
        FULL OUTER JOIN (
            SELECT p.p_promo_id,
                   p.p_discount_active
            FROM promo p
            WHERE p.p_discount_active = 'Y'
        ) promo_active
        ON joined.p_promo_id = promo_active.p_promo_id
        WHERE joined.c_customer_id NOT IN (
            SELECT c2.c_customer_id
            FROM cust c2
            WHERE c2.c_birth_year < 1950
        )
        GROUP BY joined.s_store_name, joined.d_year, joined.sr_store_sk, promo_active.p_promo_id
        HAVING SUM(joined.sr_return_amt) > (
            SELECT AVG(sr_return_amt)
            FROM store_returns
            WHERE sr_returned_date_sk = (SELECT MAX(d_date_sk) FROM d_date)
        )
    )
SELECT *
FROM agg
EXCEPT
SELECT s_store_name,
       d_year,
       0 AS total_store_return,
       0 AS total_catalog_return,
       0 AS total_web_return,
       0 AS distinct_customers,
       'LOW' AS return_level,
       NULL AS lag_store_return,
       NULL AS rn
FROM (
    SELECT s.s_store_name,
           d.d_year
    FROM store_tbl s
    CROSS JOIN d_date d
) zero_rows
ORDER BY total_store_return DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
