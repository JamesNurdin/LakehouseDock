/*
Goal: Produce a sales‑and‑returns performance snapshot per hour, gender and catalog department, aggregating store sales profit, catalog return loss and web return loss. The query joins all seven selected tables, re‑uses the ITEM and CUSTOMER_DEMOGRAPHICS tables under multiple aliases, and includes a LEFT OUTER JOIN to Web_Returns so that store‑sales rows are kept even when no web return exists.
*/
SELECT
    td_sales.t_hour                                   AS hour_of_day,
    cd_sales.cd_gender                               AS gender,
    cp.cp_department                                 AS department,
    SUM(ss.ss_net_profit)                           AS total_sales_profit,
    SUM(cr.cr_net_loss)                              AS total_catalog_return_loss,
    SUM(COALESCE(wr.wr_net_loss, 0))                AS total_web_return_loss,
    COUNT(DISTINCT ss.ss_ticket_number)             AS distinct_tickets
FROM store_sales ss

-- Join to time dimension for the sale timestamp
JOIN time_dim td_sales
  ON ss.ss_sold_time_sk = td_sales.t_time_sk

-- Join to ITEM (sales role) and reuse ITEM for catalog and web roles
JOIN item i_sales
  ON ss.ss_item_sk = i_sales.i_item_sk

-- Join to CUSTOMER_DEMOGRAPHICS for the buyer of the sale
JOIN customer_demographics cd_sales
  ON ss.ss_cdemo_sk = cd_sales.cd_demo_sk

-- Catalog Returns path (inner joins)
JOIN catalog_returns cr
  ON i_sales.i_item_sk = cr.cr_item_sk               -- rule: cr_item_sk = item.i_item_sk
JOIN item i_cat
  ON cr.cr_item_sk = i_cat.i_item_sk                  -- second alias of ITEM
JOIN time_dim td_cat
  ON cr.cr_returned_time_sk = td_cat.t_time_sk
JOIN customer_demographics cd_refund
  ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
JOIN customer_demographics cd_returning
  ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk

-- Web Returns path (LEFT OUTER to preserve sales rows)
LEFT JOIN web_returns wr
  ON i_sales.i_item_sk = wr.wr_item_sk               -- rule: wr_item_sk = item.i_item_sk
LEFT JOIN item i_web
  ON wr.wr_item_sk = i_web.i_item_sk
LEFT JOIN time_dim td_web
  ON wr.wr_returned_time_sk = td_web.t_time_sk
LEFT JOIN customer_demographics cd_wr_refund
  ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
LEFT JOIN customer_demographics cd_wr_return
  ON wr.wr_returning_cdemo_sk = cd_wr_return.cd_demo_sk

WHERE td_sales.t_hour BETWEEN 8 AND 20               -- focus on business hours
  AND cd_sales.cd_gender = 'M'                       -- example gender filter

GROUP BY
    td_sales.t_hour,
    cd_sales.cd_gender,
    cp.cp_department

ORDER BY
    total_web_return_loss DESC,
    hour_of_day ASC

LIMIT 100
