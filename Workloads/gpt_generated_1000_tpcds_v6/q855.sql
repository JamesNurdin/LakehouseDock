WITH sr_agg AS (
    SELECT
        sr_ticket_number,
        SUM(sr_return_amt)          AS total_return_amt,
        SUM(sr_net_loss)           AS total_return_loss,
        COUNT(*)                   AS return_cnt
    FROM store_returns
    WHERE sr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY sr_ticket_number
),
cr_agg AS (
    SELECT
        cr_order_number,
        SUM(cr_return_amount)       AS total_return_amount,
        SUM(cr_net_loss)            AS total_return_loss,
        COUNT(*)                    AS return_cnt
    FROM catalog_returns
    WHERE cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2001
    )
    GROUP BY cr_order_number
)
SELECT *
FROM (
    SELECT
        d.d_year                                      AS year,
        i.i_category                                  AS category,
        SUM(ss.ss_ext_sales_price)                  AS total_sales,
        SUM(sr_agg.total_return_loss)               AS total_return_loss,
        COUNT(DISTINCT ss.ss_ticket_number)         AS transaction_cnt,
        CASE WHEN SUM(ss.ss_ext_sales_price) > 1000000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_flag
    FROM store_sales ss
    JOIN sr_agg               ON ss.ss_ticket_number = sr_agg.sr_ticket_number
    JOIN date_dim d           ON ss.ss_sold_date_sk   = d.d_date_sk
    JOIN time_dim t           ON ss.ss_sold_time_sk   = t.t_time_sk
    JOIN item i               ON ss.ss_item_sk        = i.i_item_sk
    JOIN promotion p          ON ss.ss_promo_sk       = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk        = ca.ca_address_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
      AND t.t_hour BETWEEN 8 AND 18
      AND hd.hd_income_band_sk IN (4, 15)
      AND ca.ca_state = 'CA'
    GROUP BY d.d_year, i.i_category
) 
UNION ALL
SELECT
    d.d_year                                      AS year,
    i.i_category                                  AS category,
    SUM(cr_agg.total_return_amount)              AS total_sales,
    SUM(cr_agg.total_return_loss)                AS total_return_loss,
    SUM(cr_agg.return_cnt)                       AS transaction_cnt,
    CASE WHEN SUM(cr_agg.total_return_amount) > 500000 THEN 'HIGH' ELSE 'NORMAL' END AS sales_flag
FROM cr_agg
JOIN catalog_returns cr       ON cr.cr_order_number    = cr_agg.cr_order_number
JOIN date_dim d               ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t               ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i                   ON cr.cr_item_sk          = i.i_item_sk
JOIN call_center cc           ON cr.cr_call_center_sk   = cc.cc_call_center_sk
JOIN warehouse w              ON cr.cr_warehouse_sk     = w.w_warehouse_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN reason r                 ON cr.cr_reason_sk        = r.r_reason_sk
WHERE d.d_year = 2001
  AND r.r_reason_desc = 'Package was damaged'
  AND w.w_state = 'CA'
  AND hd.hd_vehicle_count >= 0
  AND ca.ca_country = 'United States'
GROUP BY d.d_year, i.i_category
ORDER BY year DESC, total_sales DESC
LIMIT 100
