WITH
    base_sales AS (
        SELECT
            cs.cs_item_sk,
            cs.cs_sold_date_sk,
            cs.cs_bill_customer_sk,
            cs.cs_net_paid,
            cs.cs_ext_discount_amt,
            i.i_brand,
            d_sales.d_year,
            c.c_first_name,
            c.c_last_name,
            sm.sm_type,
            cd.cd_gender,
            hd.hd_vehicle_count
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN date_dim d_sales ON cs.cs_sold_date_sk = d_sales.d_date_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    ),
    store_ret AS (
        SELECT
            sr.sr_item_sk,
            sr.sr_returned_date_sk,
            sr.sr_customer_sk,
            sr.sr_return_quantity,
            r.r_reason_desc,
            s.s_store_name,
            d_store.d_year AS return_year
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN date_dim d_store ON sr.sr_returned_date_sk = d_store.d_date_sk
    ),
    web_ret AS (
        SELECT
            wr.wr_item_sk,
            wr.wr_returned_date_sk,
            wr.wr_refunded_customer_sk,
            wr.wr_return_quantity,
            r.r_reason_desc AS web_reason,
            wp.wp_url,
            d_web.d_year AS web_return_year
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        JOIN date_dim d_web ON wr.wr_returned_date_sk = d_web.d_date_sk
    ),
    store_ret_agg AS (
        SELECT sr_item_sk, SUM(sr_return_quantity) AS store_return_qty
        FROM store_ret
        GROUP BY sr_item_sk
    ),
    web_ret_agg AS (
        SELECT wr_item_sk, SUM(wr_return_quantity) AS web_return_qty
        FROM web_ret
        GROUP BY wr_item_sk
    ),
    ret_combined AS (
        SELECT
            COALESCE(s.sr_item_sk, w.wr_item_sk) AS item_sk,
            s.store_return_qty,
            w.web_return_qty
        FROM store_ret_agg s
        FULL OUTER JOIN web_ret_agg w
            ON s.sr_item_sk = w.wr_item_sk
    ),
    customers_excl AS (
        SELECT c.c_customer_sk
        FROM catalog_sales cs
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        WHERE cs.cs_net_paid > 5000
    ),
    customers_in_store AS (
        SELECT c.c_customer_sk
        FROM store_returns sr
        JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    ),
    common_customers AS (
        SELECT c_customer_sk
        FROM customers_excl
        INTERSECT
        SELECT c_customer_sk
        FROM customers_in_store
    )
SELECT
    i_brand,
    d_year,
    sm_type,
    sales_category,
    unique_customers,
    total_store_return_qty,
    total_web_return_qty,
    store_return_count_for_item,
    total_sales
FROM (
    SELECT
        bs.i_brand,
        bs.d_year,
        bs.sm_type,
        CASE WHEN SUM(bs.cs_net_paid) > 20000 THEN 'BIG' ELSE 'SMALL' END AS sales_category,
        COUNT(DISTINCT bs.cs_bill_customer_sk) AS unique_customers,
        COALESCE(rc.store_return_qty, 0) AS total_store_return_qty,
        COALESCE(rc.web_return_qty, 0) AS total_web_return_qty,
        lr.cnt AS store_return_count_for_item,
        SUM(bs.cs_net_paid) AS total_sales
    FROM base_sales bs
    LEFT JOIN ret_combined rc ON bs.cs_item_sk = rc.item_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS cnt
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = bs.cs_item_sk
    ) AS lr
    WHERE bs.cs_bill_customer_sk IN (SELECT c_customer_sk FROM common_customers)
    GROUP BY ROLLUP (bs.i_brand, bs.d_year, bs.sm_type, bs.cs_bill_customer_sk, rc.store_return_qty, rc.web_return_qty, lr.cnt)
    HAVING SUM(bs.cs_net_paid) > 0
) main_result
EXCEPT
SELECT
    i_brand,
    d_year,
    sm_type,
    sales_category,
    unique_customers,
    total_store_return_qty,
    total_web_return_qty,
    store_return_count_for_item,
    total_sales
FROM (
    SELECT
        i2.i_brand,
        d2.d_year,
        sm2.sm_type,
        'EXCLUDED' AS sales_category,
        0 AS unique_customers,
        0 AS total_store_return_qty,
        0 AS total_web_return_qty,
        0 AS store_return_count_for_item,
        0 AS total_sales
    FROM item i2
    CROSS JOIN date_dim d2
    CROSS JOIN ship_mode sm2
    LIMIT 1
) ex
ORDER BY i_brand ASC NULLS LAST, d_year DESC, total_sales DESC
