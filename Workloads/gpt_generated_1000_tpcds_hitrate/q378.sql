WITH date_filter AS (
        SELECT d_date_sk
        FROM   date_dim
        WHERE  d_date = DATE '2001-01-01'
        ),
     joined_all AS (
        SELECT
            ca.ca_city,
            r.r_reason_desc,
            cr.cr_net_loss            AS catalog_net_loss,
            sr.sr_net_loss            AS store_net_loss,
            wr.wr_net_loss            AS web_net_loss,
            cs.cs_net_profit          AS sales_net_profit,
            cp.cp_department,
            sm.sm_type                AS ship_type,
            w.w_warehouse_name,
            d.d_year,
            d.d_month_seq,
            (cr.cr_net_loss + sr.sr_net_loss + wr.wr_net_loss) AS total_net_loss
        FROM catalog_returns cr
        JOIN catalog_sales cs
          ON cr.cr_order_number = cs.cs_order_number
         AND cr.cr_item_sk      = cs.cs_item_sk
        JOIN catalog_page cp
          ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
         AND cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm
          ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
         AND cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w
          ON cr.cr_warehouse_sk = w.w_warehouse_sk
         AND cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN reason r
          ON cr.cr_reason_sk = r.r_reason_sk
        JOIN store_returns sr
          ON sr.sr_reason_sk = r.r_reason_sk
        JOIN web_returns wr
          ON wr.wr_reason_sk = r.r_reason_sk
        JOIN customer_address ca
          ON ca.ca_address_sk = cr.cr_refunded_addr_sk
        JOIN date_dim d
          ON cr.cr_returned_date_sk = d.d_date_sk
         AND cs.cs_sold_date_sk   = d.d_date_sk
         AND sr.sr_returned_date_sk = d.d_date_sk
         AND wr.wr_returned_date_sk = d.d_date_sk
         AND d.d_date_sk IN (SELECT d_date_sk FROM date_filter)
        JOIN inventory i
          ON i.inv_date_sk = d.d_date_sk
         AND i.inv_warehouse_sk = w.w_warehouse_sk
        WHERE ca.ca_city IN ('Greenville','Oakland','Farmington')
          AND cp.cp_department = 'Electronics'
          AND sm.sm_type = 'AIR'
          AND w.w_state = 'CA'
          AND d.d_year = 2001
    ),
    aggregated AS (
        SELECT
            ca_city,
            r_reason_desc,
            SUM(total_net_loss)                     AS sum_total_loss,
            SUM(sales_net_profit)                   AS sum_sales_profit,
            CASE WHEN SUM(total_net_loss) > 1000 THEN 'HIGH' ELSE 'MEDIUM' END AS loss_category
        FROM joined_all
        GROUP BY ca_city, r_reason_desc
    ),
    ranked AS (
        SELECT
            ca_city,
            r_reason_desc,
            sum_total_loss,
            sum_sales_profit,
            loss_category,
            ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY sum_total_loss DESC) AS rn
        FROM aggregated
        WHERE sum_total_loss > (
                SELECT AVG(cr.cr_net_loss)
                FROM catalog_returns cr
                WHERE cr.cr_returned_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_date = DATE '2001-01-01')
            )
    )
SELECT
    ca_city,
    r_reason_desc,
    sum_total_loss,
    sum_sales_profit,
    loss_category,
    rn AS rank_within_city
FROM ranked
WHERE rn <= 3
ORDER BY loss_category DESC, sum_total_loss DESC
LIMIT 100
