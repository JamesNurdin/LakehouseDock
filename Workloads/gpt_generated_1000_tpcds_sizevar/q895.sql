WITH
    /* Sampled inventory and pre‑aggregate quantity on hand */
    inv_agg AS (
        SELECT
            inv_item_sk,
            SUM(inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        GROUP BY inv_item_sk
    ),
    /* Sampled and filtered catalog returns */
    cr_pre AS (
        SELECT
            cr.cr_item_sk,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_call_center_sk,
            cr.cr_catalog_page_sk,
            cr.cr_ship_mode_sk,
            cr.cr_reason_sk,
            cr.cr_returned_date_sk,
            cr.cr_refunded_customer_sk,
            cr.cr_refunded_cdemo_sk
        FROM catalog_returns cr
        TABLESAMPLE BERNOULLI (5)
        WHERE cr.cr_return_amount > 100
          AND cr.cr_returned_date_sk IN (
                SELECT d_date_sk FROM date_dim WHERE d_year = 2001 AND d_month_seq = 5
          )
    ),
    /* Sampled and filtered web returns */
    wr_pre AS (
        SELECT
            wr.wr_item_sk,
            wr.wr_return_amt,
            wr.wr_return_quantity,
            wr.wr_web_page_sk,
            wr.wr_reason_sk,
            wr.wr_returned_date_sk,
            wr.wr_refunded_customer_sk,
            wr.wr_refunded_cdemo_sk
        FROM web_returns wr
        WHERE wr.wr_return_amt > 50
          AND wr.wr_returned_date_sk IN (
                SELECT d_date_sk FROM date_dim WHERE d_year = 2001 AND d_month_seq = 5
          )
    ),
    /* Full catalog‑return side with all required dimensions */
    cr_full AS (
        SELECT
            crp.cr_item_sk,
            crp.cr_return_amount,
            crp.cr_return_quantity,
            crp.cr_call_center_sk,
            crp.cr_catalog_page_sk,
            crp.cr_ship_mode_sk,
            crp.cr_reason_sk,
            crp.cr_returned_date_sk,
            crp.cr_refunded_customer_sk,
            crp.cr_refunded_cdemo_sk,
            cc.cc_name,
            cp.cp_department,
            sm.sm_type,
            r.r_reason_desc,
            d.d_year,
            i.i_item_id,
            i.i_category,
            i.i_manufact_id,
            cust.c_customer_id,
            cd.cd_gender
        FROM cr_pre crp
        JOIN call_center cc           ON crp.cr_call_center_sk   = cc.cc_call_center_sk
        JOIN catalog_page cp           ON crp.cr_catalog_page_sk  = cp.cp_catalog_page_sk
        JOIN ship_mode sm              ON crp.cr_ship_mode_sk     = sm.sm_ship_mode_sk
        JOIN reason r                  ON crp.cr_reason_sk        = r.r_reason_sk
        JOIN date_dim d                ON crp.cr_returned_date_sk = d.d_date_sk
        JOIN item i                    ON crp.cr_item_sk          = i.i_item_sk
        JOIN customer cust             ON crp.cr_refunded_customer_sk = cust.c_customer_sk
        JOIN customer_demographics cd  ON crp.cr_refunded_cdemo_sk   = cd.cd_demo_sk
    ),
    /* Full web‑return side with all required dimensions */
    wr_full AS (
        SELECT
            wrp.wr_item_sk,
            wrp.wr_return_amt,
            wrp.wr_return_quantity,
            wrp.wr_web_page_sk,
            wrp.wr_reason_sk,
            wrp.wr_returned_date_sk,
            wrp.wr_refunded_customer_sk,
            wrp.wr_refunded_cdemo_sk,
            wp.wp_type,
            r.r_reason_desc AS web_reason_desc,
            d.d_year AS wr_year,
            i.i_item_id,
            i.i_category,
            i.i_manufact_id,
            cust.c_customer_id,
            cd.cd_gender
        FROM wr_pre wrp
        JOIN web_page wp               ON wrp.wr_web_page_sk = wp.wp_web_page_sk
        JOIN reason r                  ON wrp.wr_reason_sk    = r.r_reason_sk
        JOIN date_dim d                ON wrp.wr_returned_date_sk = d.d_date_sk
        JOIN item i                    ON wrp.wr_item_sk      = i.i_item_sk
        JOIN customer cust             ON wrp.wr_refunded_customer_sk = cust.c_customer_sk
        JOIN customer_demographics cd  ON wrp.wr_refunded_cdemo_sk   = cd.cd_demo_sk
    )
SELECT
    COALESCE(cr_full.cr_item_sk, wr_full.wr_item_sk)                         AS item_sk,
    COALESCE(cr_full.i_item_id, wr_full.i_item_id)                           AS item_id,
    COALESCE(cr_full.i_category, wr_full.i_category)                         AS category,
    SUM(COALESCE(cr_full.cr_return_amount, 0))                               AS total_catalog_return_amount,
    SUM(COALESCE(wr_full.wr_return_amt, 0))                                  AS total_web_return_amount,
    COUNT(DISTINCT COALESCE(cr_full.c_customer_id, wr_full.c_customer_id))  AS distinct_customers,
    COUNT(DISTINCT COALESCE(cr_full.r_reason_desc, wr_full.web_reason_desc)) AS distinct_return_reasons,
    CASE
        WHEN SUM(COALESCE(cr_full.cr_return_quantity, 0)) >
             SUM(COALESCE(wr_full.wr_return_quantity, 0))
        THEN 'CatalogHigher'
        ELSE 'WebHigher'
    END                                                                     AS higher_return_source,
    ai.total_qty_on_hand                                                     AS inventory_on_hand
FROM cr_full
FULL OUTER JOIN wr_full
    ON cr_full.cr_item_sk = wr_full.wr_item_sk
LEFT JOIN inv_agg ai
    ON ai.inv_item_sk = COALESCE(cr_full.cr_item_sk, wr_full.wr_item_sk)
WHERE COALESCE(cr_full.cr_call_center_sk, -1) NOT IN (
        SELECT cc.cc_call_center_sk FROM call_center cc WHERE cc.cc_state = 'CA'
      )
  AND COALESCE(cr_full.d_year, wr_full.wr_year) = 2001
  AND COALESCE(cr_full.i_manufact_id, wr_full.i_manufact_id) IN (167, 479)
  AND COALESCE(cr_full.cd_gender, wr_full.cd_gender) = 'M'
GROUP BY
    COALESCE(cr_full.cr_item_sk, wr_full.wr_item_sk),
    COALESCE(cr_full.i_item_id, wr_full.i_item_id),
    COALESCE(cr_full.i_category, wr_full.i_category),
    ai.total_qty_on_hand,
    COALESCE(cr_full.d_year, wr_full.wr_year)
ORDER BY total_catalog_return_amount DESC
LIMIT 100
