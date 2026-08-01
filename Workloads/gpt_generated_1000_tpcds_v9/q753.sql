WITH item_aggregates AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(sr.sr_net_loss) AS total_store_return_loss,
        SUM(cr.cr_net_loss) AS total_catalog_return_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_on_hand,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_sales_tickets
    FROM item i
    JOIN store_sales ss
        ON i.i_item_sk = ss.ss_item_sk
    JOIN date_dim d_ss
        ON ss.ss_sold_date_sk = d_ss.d_date_sk
    JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND i.i_item_sk = sr.sr_item_sk
    LEFT JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk
    LEFT JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    LEFT JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    LEFT JOIN web_returns wr
        ON i.i_item_sk = wr.wr_item_sk
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
        AND d_ss.d_date_sk = inv.inv_date_sk
    WHERE d_ss.d_year = 2001
      AND i.i_current_price > 20
      AND hd_ss.hd_vehicle_count >= 0
      AND cd_ss.cd_gender = 'M'
      AND cp.cp_department = 'Sports'
      AND sm.sm_carrier = 'UPS'
      AND cr.cr_return_quantity > 0
    GROUP BY i.i_item_sk, i.i_item_desc, i.i_category, i.i_brand
)
SELECT
    ia.i_category,
    ia.i_brand,
    SUM(ia.total_sales_amount) AS category_sales,
    SUM(ia.total_store_return_loss + ia.total_catalog_return_loss + ia.total_web_return_loss) AS category_total_return_loss,
    SUM(ia.total_inventory_on_hand) AS category_inventory,
    (SUM(ia.total_store_return_loss + ia.total_catalog_return_loss + ia.total_web_return_loss) / NULLIF(SUM(ia.total_sales_amount), 0)) AS loss_to_sales_ratio,
    AVG(ia.total_inventory_on_hand) AS avg_inventory_per_item,
    SUM(ia.total_quantity_sold) AS category_quantity_sold,
    COUNT(DISTINCT ia.i_item_sk) AS distinct_items
FROM item_aggregates ia
GROUP BY ia.i_category, ia.i_brand
HAVING SUM(ia.total_sales_amount) > 10000
   AND SUM(ia.total_store_return_loss + ia.total_catalog_return_loss + ia.total_web_return_loss) > 0
   AND AVG(ia.total_inventory_on_hand) > 10
   AND SUM(ia.total_quantity_sold) > 1000
   AND COUNT(DISTINCT ia.i_item_sk) >= 5
ORDER BY loss_to_sales_ratio DESC
LIMIT 100
