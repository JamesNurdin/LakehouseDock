WITH sales_union AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ss.ss_net_profit AS net_amount
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           ws.ws_net_profit AS net_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           -sr.sr_net_loss AS net_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk

    UNION ALL

    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           -cr.cr_net_loss AS net_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
sales_agg AS (
    SELECT su.d_year,
           su.d_month_seq,
           su.i_category,
           sum(su.net_amount) AS total_net_amount
    FROM sales_union su
    WHERE su.d_year = 2002
    GROUP BY su.d_year,
             su.d_month_seq,
             su.i_category
),
inventory_agg AS (
    SELECT d.d_year,
           d.d_month_seq,
           i.i_category,
           sum(inv.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year,
             d.d_month_seq,
             i.i_category
)
SELECT s.d_year,
       s.d_month_seq,
       s.i_category,
       s.total_net_amount,
       i.total_inventory_qty
FROM sales_agg s
LEFT JOIN inventory_agg i
  ON s.d_year = i.d_year
 AND s.d_month_seq = i.d_month_seq
 AND s.i_category = i.i_category
ORDER BY s.d_year,
         s.d_month_seq,
         s.i_category
