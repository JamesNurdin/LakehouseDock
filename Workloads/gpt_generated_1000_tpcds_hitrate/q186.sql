/* goal: Identify the top‑selling items by net profit for the year 2002, filtering by brand, call‑center location, shipping mode and return reason, while excluding orders that had a catalog return. The query joins all 16 selected TPC‑DS tables, applies multiple predicates, uses a ROW_NUMBER window function for ranking, and orders the final result. */
WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_net_profit,
        cs.cs_quantity
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 0
)
SELECT
    i.i_item_id,
    i.i_product_name,
    d_year.d_year,
    d_month.d_month_seq,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    r.r_reason_desc,
    ws.web_name,
    wp.wp_url,
    inv.inv_quantity_on_hand,
    fs.cs_net_profit,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY fs.cs_net_profit DESC) AS profit_rank
FROM filtered_sales fs
JOIN date_dim d_year               ON fs.cs_sold_date_sk = d_year.d_date_sk
JOIN time_dim t                    ON fs.cs_sold_time_sk = t.t_time_sk
JOIN item i                        ON fs.cs_item_sk = i.i_item_sk
JOIN call_center cc                ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp               ON fs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm                  ON fs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_demographics cd      ON fs.cs_bill_cdemo_sk = cd.cd_demo_sk
LEFT JOIN inventory inv            ON inv.inv_item_sk = i.i_item_sk
                                   AND inv.inv_date_sk = d_year.d_date_sk
JOIN store_sales ss                ON ss.ss_item_sk = i.i_item_sk
                                   AND ss.ss_sold_date_sk = d_year.d_date_sk
JOIN date_dim d_month              ON ss.ss_sold_date_sk = d_month.d_date_sk
JOIN store_returns sr              ON sr.sr_ticket_number = ss.ss_ticket_number
                                   AND sr.sr_item_sk = i.i_item_sk
JOIN reason r                      ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr               ON wr.wr_item_sk = i.i_item_sk
                                   AND wr.wr_returned_date_sk = d_year.d_date_sk
JOIN web_page wp                  ON wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN web_site ws                  ON ws.web_open_date_sk = d_year.d_date_sk
WHERE
    d_year.d_year = 2002
    AND i.i_brand = 'Brand#45'
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc LIKE '%damage%'
    AND fs.cs_order_number NOT IN (
        SELECT cr.cr_order_number
        FROM catalog_returns cr
        WHERE cr.cr_return_quantity > 0
    )
ORDER BY fs.cs_net_profit DESC
LIMIT 100
