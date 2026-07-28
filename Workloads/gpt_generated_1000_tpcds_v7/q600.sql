WITH catalog_enriched AS (
        SELECT
            cr.cr_item_sk,
            cr.cr_returned_date_sk,
            cr.cr_returned_time_sk,
            cr.cr_return_amount,
            cc.cc_name               AS call_center_name,
            cp.cp_type               AS catalog_page_type,
            sm.sm_type               AS ship_mode_type,
            w.w_warehouse_name,
            r.r_reason_desc          AS return_reason
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode    sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse    w  ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason       r  ON cr.cr_reason_sk = r.r_reason_sk
    ),
    store_returns_enriched AS (
        SELECT
            sr.sr_ticket_number,
            sr.sr_item_sk,
            sr.sr_returned_date_sk,
            sr.sr_return_time_sk,
            sr.sr_return_amt,
            r.r_reason_desc AS return_reason,
            sr.sr_store_sk
        FROM store_returns sr
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    )
SELECT
    s.s_store_id,
    d.d_year,
    i.i_brand,
    i.i_category,
    SUM(ss.ss_net_paid)                     AS total_net_paid,
    SUM(ss.ss_quantity)                     AS total_quantity,
    AVG(ss.ss_ext_discount_amt)            AS avg_discount,
    SUM(COALESCE(cr_en.cr_return_amount, 0)) AS total_catalog_returns,
    SUM(COALESCE(sr_en.sr_return_amt, 0))    AS total_store_returns,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
FROM store_sales ss
JOIN date_dim d               ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t               ON ss.ss_sold_time_sk = t.t_time_sk
JOIN item i                   ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca      ON ss.ss_addr_sk = ca.ca_address_sk
JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p              ON ss.ss_promo_sk = p.p_promo_sk
JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
JOIN warehouse w_inv          ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
LEFT JOIN catalog_enriched cr_en
       ON ss.ss_item_sk = cr_en.cr_item_sk
      AND ss.ss_sold_date_sk = cr_en.cr_returned_date_sk
      AND ss.ss_sold_time_sk = cr_en.cr_returned_time_sk
LEFT JOIN store_returns_enriched sr_en
       ON ss.ss_ticket_number = sr_en.sr_ticket_number
WHERE d.d_year = 2002
  AND s.s_state = 'CA'
  AND i.i_brand = 'Brand#12'
  AND cd.cd_gender = 'M'
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_id,
    d.d_year,
    i.i_brand,
    i.i_category
HAVING SUM(ss.ss_net_paid) > 10000
ORDER BY total_net_paid DESC
