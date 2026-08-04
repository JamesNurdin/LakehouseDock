WITH
  catalog_join AS (
    SELECT
      cr.cr_returned_date_sk                                   AS cr_returned_date_sk,
      d.d_date                                                 AS d_date,
      i.i_item_id                                              AS i_item_id,
      i.i_category                                             AS i_category,
      cp.cp_catalog_page_id                                    AS cp_catalog_page_id,
      w.w_warehouse_name                                       AS w_warehouse_name,
      sm.sm_ship_mode_id                                       AS sm_ship_mode_id,
      r.r_reason_desc                                          AS r_reason_desc,
      ca.ca_state                                              AS ca_state,
      cd.cd_gender                                             AS cd_gender,
      wp.wp_url                                                AS wp_url,
      cr.cr_return_amount                                      AS cr_return_amount,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY cr.cr_return_amount DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d          ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i               ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w          ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm         ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer_address ca  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp          ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (2, 4, 7)
      AND sm.sm_code = 'AIR'
      AND ca.ca_state = 'TX'
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
              AND sr.sr_returned_date_sk = d.d_date_sk
          )
  ),
  store_join AS (
    SELECT
      sr.sr_returned_date_sk                                   AS cr_returned_date_sk,
      d.d_date                                                 AS d_date,
      i.i_item_id                                              AS i_item_id,
      i.i_category                                             AS i_category,
      CAST(NULL AS varchar)                                    AS cp_catalog_page_id,
      CAST(NULL AS varchar)                                    AS w_warehouse_name,
      CAST(NULL AS varchar)                                    AS sm_ship_mode_id,
      CAST(NULL AS varchar)                                    AS r_reason_desc,
      ca.ca_state                                              AS ca_state,
      cd.cd_gender                                             AS cd_gender,
      CAST(NULL AS varchar)                                    AS wp_url,
      sr.sr_return_amt                                         AS cr_return_amount,
      ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY sr.sr_return_amt DESC) AS rn
    FROM store_returns sr
    JOIN date_dim d          ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i               ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_address ca  ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (2, 4, 7)
      AND ca.ca_state = 'TX'
  ),
  combined AS (
    SELECT * FROM catalog_join
    UNION
    SELECT * FROM store_join
  ),
  item_keys AS (
    SELECT i_item_id FROM combined
  ),
  store_items AS (
    SELECT DISTINCT i.i_item_id
    FROM store_returns sr
    JOIN date_dim d          ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i               ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (2, 4, 7)
  ),
  diff_items AS (
    SELECT i_item_id FROM item_keys
    EXCEPT
    SELECT i_item_id FROM store_items
  ),
  final_full AS (
    SELECT
      fb.cr_returned_date_sk,
      fb.d_date,
      fb.i_item_id,
      fb.i_category,
      fb.cp_catalog_page_id,
      fb.w_warehouse_name,
      fb.sm_ship_mode_id,
      fb.r_reason_desc,
      fb.ca_state,
      fb.cd_gender,
      fb.wp_url,
      fb.cr_return_amount,
      DENSE_RANK() OVER (PARTITION BY fb.ca_state ORDER BY fb.cr_return_amount DESC) AS state_rank,
      CASE WHEN di.i_item_id IS NOT NULL THEN 'CatalogOnly' ELSE 'StoreOrOther' END AS source_flag
    FROM combined fb
    FULL OUTER JOIN diff_items di ON fb.i_item_id = di.i_item_id
  )
SELECT *
FROM final_full
WHERE source_flag = 'CatalogOnly'
ORDER BY state_rank, cr_return_amount DESC
LIMIT 100
