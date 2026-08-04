WITH
    /* Sales aggregation per date, store and item */
    sales_agg AS (
        SELECT
            d.d_date,
            s.s_store_name,
            i.i_item_id,
            i.i_item_sk,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            SUM(ss.ss_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
          AND s.s_state = 'CA'
          AND i.i_brand = 'Brand#12'
          AND p.p_discount_active = 'Y'
          AND t.t_hour BETWEEN 9 AND 18
        GROUP BY d.d_date, s.s_store_name, i.i_item_id, i.i_item_sk
    ),
    /* Store returns aggregation */
    returns_agg AS (
        SELECT
            d.d_date,
            s.s_store_name,
            i.i_item_id,
            i.i_item_sk,
            SUM(sr.sr_return_amt) AS total_return_amt,
            COUNT(*) AS return_cnt
        FROM store_returns sr
        JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE d.d_year = 2001
          AND s.s_state = 'CA'
          AND i.i_brand = 'Brand#12'
          AND t.t_hour BETWEEN 9 AND 18
        GROUP BY d.d_date, s.s_store_name, i.i_item_id, i.i_item_sk
    ),
    /* Catalog returns aggregation */
    catalog_agg AS (
        SELECT
            d.d_date,
            w.w_warehouse_name,
            i.i_item_id,
            i.i_item_sk,
            SUM(cr.cr_return_amount) AS catalog_return_amount,
            COUNT(*) AS catalog_return_cnt
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        WHERE d.d_year = 2001
          AND cp.cp_type = 'digital'
          AND cr.cr_return_amount > 50
        GROUP BY d.d_date, w.w_warehouse_name, i.i_item_id, i.i_item_sk
    ),
    /* Web returns aggregation */
    web_agg AS (
        SELECT
            d.d_date,
            i.i_item_id,
            i.i_item_sk,
            SUM(wr.wr_return_amt) AS web_return_amount,
            COUNT(*) AS web_return_cnt
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
        WHERE d.d_year = 2001
          AND wr.wr_return_amt > 30
        GROUP BY d.d_date, i.i_item_id, i.i_item_sk
    ),
    /* Inventory aggregation */
    inventory_agg AS (
        SELECT
            d.d_date,
            w.w_warehouse_name,
            i.i_item_id,
            i.i_item_sk,
            SUM(inv.inv_quantity_on_hand) AS total_on_hand
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        JOIN item i ON inv.inv_item_sk = i.i_item_sk
        JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE d.d_year = 2001
          AND inv.inv_quantity_on_hand > 0
        GROUP BY d.d_date, w.w_warehouse_name, i.i_item_id, i.i_item_sk
    ),
    /* Item keys appearing in catalog returns */
    key_set_a AS (
        SELECT DISTINCT cr.cr_item_sk AS item_sk
        FROM catalog_returns cr
        JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND cr.cr_return_amount > 100
    ),
    /* Item keys appearing in inventory */
    key_set_c AS (
        SELECT DISTINCT inv.inv_item_sk AS item_sk
        FROM inventory inv
        JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND inv.inv_quantity_on_hand > 5
    ),
    /* Items present in catalog returns but not in inventory */
    item_diff AS (
        SELECT item_sk FROM key_set_a
        EXCEPT
        SELECT item_sk FROM key_set_c
    ),
    /* Store‑date combinations that exist in both sales and returns */
    common_store_date AS (
        SELECT d_date, s_store_name FROM sales_agg
        INTERSECT
        SELECT d_date, s_store_name FROM returns_agg
    )
SELECT
    COALESCE(sa.d_date, ra.d_date) AS date,
    COALESCE(sa.s_store_name, ra.s_store_name) AS store_name,
    COALESCE(sa.i_item_id, ra.i_item_id, ca.i_item_id, wa.i_item_id, ia.i_item_id) AS item_id,
    sa.total_sales,
    ra.total_return_amt,
    ca.catalog_return_amount,
    wa.web_return_amount,
    ia.total_on_hand
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra
    ON sa.d_date = ra.d_date
   AND sa.s_store_name = ra.s_store_name
   AND sa.i_item_id = ra.i_item_id
LEFT JOIN catalog_agg ca
    ON sa.d_date = ca.d_date
   AND sa.i_item_id = ca.i_item_id
LEFT JOIN web_agg wa
    ON sa.d_date = wa.d_date
   AND sa.i_item_id = wa.i_item_id
LEFT JOIN inventory_agg ia
    ON sa.d_date = ia.d_date
   AND sa.i_item_id = ia.i_item_id
JOIN common_store_date csd
    ON csd.d_date = COALESCE(sa.d_date, ra.d_date)
   AND csd.s_store_name = COALESCE(sa.s_store_name, ra.s_store_name)
JOIN item_diff idf
    ON idf.item_sk = COALESCE(sa.i_item_sk, ra.i_item_sk)
WHERE (sa.total_sales > 1000 OR ra.total_return_amt > 200)
  AND (ca.catalog_return_amount IS NOT NULL OR wa.web_return_amount IS NOT NULL)
  AND ia.total_on_hand IS NOT NULL
  AND sa.s_store_name IS NOT NULL
  AND COALESCE(sa.d_date, ra.d_date) >= DATE '2001-01-01'
LIMIT 100
